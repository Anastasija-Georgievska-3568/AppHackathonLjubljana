import { useEffect, useRef, useState } from "react";
import { nextTurn, coachTurn, finalVerdict, fetchTTS, transcribe, track } from "./api.js";
import { ConfidenceMeter, TypeOnText, MicButton } from "./components.jsx";

// Voice works in every browser that can record audio (we transcribe server-side
// via Whisper) — unlike the built-in Web Speech API, which Firefox/Brave block.
const supportsVoice =
  typeof navigator !== "undefined" &&
  !!navigator.mediaDevices?.getUserMedia &&
  typeof window !== "undefined" &&
  typeof window.MediaRecorder !== "undefined";

const MAX_TURNS = 5;

export default function Challenge({ scenario, onFinish, onExit, isDesktop }) {
  const [turns, setTurns] = useState([]); // {speaker, text}
  const [score, setScore] = useState(50); // running confidence score 0–100 (from COACH)
  const [coachNote, setCoachNote] = useState(null); // latest coach tip
  const [phase, setPhase] = useState("intro"); // intro | aiSpeaking | awaiting | recording | transcribing | sending | finished
  const [draft, setDraft] = useState("");
  const [error, setError] = useState(null);
  const [revealSpeed, setRevealSpeed] = useState(40); // ms per char for type-on

  const audioRef = useRef(null);
  const mediaRecRef = useRef(null);
  const chunksRef = useRef([]);
  const streamRef = useRef(null);
  const transcriptEndRef = useRef(null);
  const startedRef = useRef(false);
  const lastAttemptRef = useRef([]); // history of the last manager-reply attempt, for retry
  const scoreRef = useRef(50); // latest score for the async debrief
  const lastNoteRef = useRef(""); // previous coach note, so the next one doesn't repeat it

  const userTurnCount = turns.filter((t) => t.speaker === "user").length;

  // Kick off with the AI's opening line.
  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;
    track("start", scenario.id);
    runAITurn([]);
    return () => {
      audioRef.current?.pause();
      try { mediaRecRef.current?.stop(); } catch { /* ignore */ }
      streamRef.current?.getTracks().forEach((t) => t.stop());
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    transcriptEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [turns, phase]);

  // Fetch the TTS clip AND read its duration up front, so the text can be
  // revealed in lockstep with the voice instead of finishing in silence.
  async function prepareAudio(text, voiceHint) {
    const url = await fetchTTS(text, voiceHint);
    if (!url) return { audio: null, url: null, durationMs: null };
    const audio = new Audio(url);
    const durationMs = await new Promise((resolve) => {
      let settled = false;
      const done = (v) => { if (!settled) { settled = true; resolve(v); } };
      audio.onloadedmetadata = () =>
        done(isFinite(audio.duration) && audio.duration > 0 ? audio.duration * 1000 : null);
      audio.onerror = () => done(null);
      setTimeout(() => done(null), 1000); // never hang on metadata
    });
    return { audio, url, durationMs };
  }

  function playPrepared(prepared, text) {
    if (audioRef.current) { try { audioRef.current.pause(); } catch { /* ignore */ } }
    if (!prepared || !prepared.audio) {
      // No OpenAI clip — fall back to the browser's built-in voice.
      try {
        const u = new SpeechSynthesisUtterance(text);
        u.lang = "en-US";
        window.speechSynthesis.cancel();
        window.speechSynthesis.speak(u);
      } catch { /* ignore */ }
      return;
    }
    const { audio, url } = prepared;
    audioRef.current = audio;
    audio.onended = () => url && URL.revokeObjectURL(url);
    audio.play().catch(() => {});
  }

  async function runAITurn(history) {
    lastAttemptRef.current = history; // remember for retry on failure
    setPhase("aiSpeaking"); // keeps the "…" indicator up while we prep the voice
    setError(null);
    const isFinalTurn = history.filter((t) => t.speaker === "user").length >= MAX_TURNS;
    let res;
    try {
      res = await nextTurn(scenario, history, isFinalTurn);
    } catch {
      setError("The other person went quiet — connection hiccup.");
      setPhase("awaiting");
      return;
    }
    const aiTurn = { speaker: "ai", text: res.say };
    const newTurns = [...history, aiTurn];

    // Reveal the text + advance the phase. Pace the type-on to the clip length
    // (when known) so the words finish about when the voice does.
    const reveal = (durationMs) => {
      const perChar =
        durationMs && res.say.length
          ? Math.min(80, Math.max(26, durationMs / res.say.length))
          : 40;
      setRevealSpeed(perChar);
      setTurns(newTurns);
      if (res.shouldEnd || isFinalTurn) finishSession(newTurns);
      else setPhase("awaiting");
    };

    // Wait for the voice to be ready before showing text — but cap the wait so
    // a slow/failed TTS can't strand the user staring at "…".
    const prepPromise = prepareAudio(res.say, scenario.aiVoiceHint);
    const prepared = await Promise.race([
      prepPromise,
      new Promise((r) => setTimeout(() => r("TIMEOUT"), 3500)),
    ]);

    if (prepared === "TIMEOUT") {
      reveal(null); // show text now; play the voice whenever it lands
      prepPromise.then((p) => playPrepared(p, res.say));
    } else {
      reveal(prepared.durationMs);
      playPrepared(prepared, res.say);
    }
  }

  async function finishSession(finalTurns) {
    setPhase("finished");
    track("complete", scenario.id);
    const verdict = await finalVerdict(scenario, finalTurns, scoreRef.current);
    onFinish({ verdict, scenario, finalScore: verdict.finalScore });
  }

  // COACH: evaluate the user's latest message in parallel with the manager reply.
  // Best-effort — a coaching hiccup never blocks the conversation.
  async function runCoach(history) {
    const res = await coachTurn(scenario, history, lastNoteRef.current);
    if (!res) return;
    scoreRef.current = res.score;
    setScore(res.score);
    if (res.note) {
      lastNoteRef.current = res.note;
      setCoachNote(res.note);
    }
  }

  function submitUser(text) {
    const trimmed = text.trim();
    if (!trimmed) return;
    // Cut off any AI voice still playing so it doesn't talk over the user.
    if (audioRef.current) { try { audioRef.current.pause(); } catch { /* ignore */ } }
    setDraft("");
    setCoachNote(null); // clear the old tip while this turn is evaluated
    const userTurn = { speaker: "user", text: trimmed };
    const history = [...turns, userTurn];
    setTurns(history);
    setPhase("sending");
    runCoach(history); // COACH (parallel, best-effort)
    runAITurn(history); // CHARACTER (manager reply)
  }

  // Record mic audio, then transcribe it server-side (Whisper) on stop.
  async function toggleRecord() {
    if (phase === "recording") {
      try { mediaRecRef.current?.stop(); } catch { /* ignore */ }
      return;
    }
    let stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch {
      setError("Microphone blocked — allow access or type instead.");
      return;
    }
    streamRef.current = stream;
    chunksRef.current = [];
    setDraft("");
    const mr = new MediaRecorder(stream);
    mediaRecRef.current = mr;
    mr.ondataavailable = (e) => { if (e.data.size) chunksRef.current.push(e.data); };
    mr.onstop = async () => {
      stream.getTracks().forEach((t) => t.stop());
      const blob = new Blob(chunksRef.current, { type: mr.mimeType || "audio/webm" });
      setPhase("transcribing");
      const text = await transcribe(blob);
      if (text) submitUser(text);
      else {
        setError("Couldn't catch that — try again or type.");
        setPhase("awaiting");
      }
    };
    setError(null);
    mr.start();
    setPhase("recording");
  }

  const inputDisabled =
    phase === "sending" || phase === "aiSpeaking" || phase === "transcribing";

  const turnsBadge = (
    <span className="tag">{Math.min(userTurnCount, MAX_TURNS)}/{MAX_TURNS}</span>
  );

  const transcriptEl = (
    <div className="transcript">
      {turns.map((t, i) =>
        t.speaker === "ai" ? (
          <div className="bubble ai" key={i}>
            {i === turns.length - 1 ? (
              <TypeOnText text={t.text} speed={revealSpeed} />
            ) : (
              t.text
            )}
          </div>
        ) : (
          <div className="bubble user" key={i}>{t.text}</div>
        )
      )}
      {coachNote && phase !== "finished" && (
        <div className="callout fadein" key={coachNote}>→ {coachNote}</div>
      )}
      {(phase === "aiSpeaking" || phase === "sending") && (
        <div className="bubble ai thinking"><span>•</span><span>•</span><span>•</span></div>
      )}
      <div ref={transcriptEndRef} />
    </div>
  );

  const recording = phase === "recording";
  const hasDraft = draft.trim().length > 0;
  const inputEl =
    phase === "finished" ? (
      <div className="df-micro" style={{ textAlign: "center" }}>scoring your round…</div>
    ) : (
      <div className="input-bar">
        <textarea
          className="text-input"
          rows={1}
          placeholder={recording ? "listening…" : "type if speaking feels like too much…"}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              submitUser(draft);
            }
          }}
          disabled={inputDisabled}
          readOnly={recording}
        />
        {recording ? (
          <MicButton recording disabled={false} onClick={toggleRecord} />
        ) : hasDraft ? (
          <button
            className="mic-btn send"
            disabled={inputDisabled}
            onClick={() => submitUser(draft)}
            aria-label="Send"
          >
            ↑
          </button>
        ) : supportsVoice ? (
          <MicButton recording={false} disabled={inputDisabled} onClick={toggleRecord} />
        ) : null}
      </div>
    );

  const errorEl = error && (
    <div className="row" style={{ justifyContent: "center", gap: 10 }}>
      <span className="df-micro" style={{ color: "var(--warning)" }}>{error}</span>
      <button
        className="tag pink"
        style={{ cursor: "pointer" }}
        onClick={() => runAITurn(lastAttemptRef.current)}
      >
        ↻ retry
      </button>
    </div>
  );

  return (
    <div className="app-shell">
      <div className="screen" style={{ position: "relative" }}>
        <div className="topbar">
          <button className="icon-btn" onClick={onExit}>←</button>
          <div>
            <div className="df-micro">{scenario.personaLabel || scenario.personaTypeLabel}</div>
            <div style={{ fontWeight: 800 }}>{scenario.title}</div>
          </div>
          <div className="spacer" />
          {turnsBadge}
        </div>

        <ConfidenceMeter value={score / 100} />
        {transcriptEl}
        {errorEl}
        {inputEl}
        {supportsVoice && phase !== "finished" && (
          <div className="df-micro" style={{ textAlign: "center", opacity: 0.7 }}>
            🎙 voice is transcribed by OpenAI
          </div>
        )}
      </div>
    </div>
  );
}
