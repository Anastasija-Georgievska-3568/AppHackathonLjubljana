import { useEffect, useRef, useState } from "react";
import { nextTurn, finalVerdict, fetchTTS, transcribe, track } from "./api.js";
import { ConfidenceMeter, TypeOnText, MicButton } from "./components.jsx";

// Voice works in every browser that can record audio (we transcribe server-side
// via Whisper) — unlike the built-in Web Speech API, which Firefox/Brave block.
const supportsVoice =
  typeof navigator !== "undefined" &&
  !!navigator.mediaDevices?.getUserMedia &&
  typeof window !== "undefined" &&
  typeof window.MediaRecorder !== "undefined";

const MAX_TURNS = 6;

export default function Challenge({ scenario, onFinish, onExit, isDesktop }) {
  const [turns, setTurns] = useState([]); // {speaker, text, callout}
  const [confidence, setConfidence] = useState(0.55);
  const [phase, setPhase] = useState("intro"); // intro | aiSpeaking | awaiting | recording | transcribing | sending | finished
  const [draft, setDraft] = useState("");
  const [error, setError] = useState(null);
  const [revealSpeed, setRevealSpeed] = useState(40); // ms per char for type-on

  const audioRef = useRef(null);
  const mediaRecRef = useRef(null);
  const chunksRef = useRef([]);
  const streamRef = useRef(null);
  const partialBusyRef = useRef(false); // one interim transcription in flight at a time
  const lastPartialRef = useRef(""); // latest interim transcript (fallback on stop)
  const transcriptEndRef = useRef(null);
  const startedRef = useRef(false);

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
    setPhase("aiSpeaking"); // keeps the "…" indicator up while we prep the voice
    setError(null);
    const isFinalTurn = history.filter((t) => t.speaker === "user").length >= MAX_TURNS;
    let res;
    try {
      res = await nextTurn(scenario, history, isFinalTurn);
    } catch (e) {
      setError(e.message || "Something went wrong");
      setPhase("awaiting");
      return;
    }
    const newConf = clamp(confidenceRef.current + res.confidenceDelta / 100);
    confidenceRef.current = newConf;
    setConfidence(newConf);

    const aiTurn = { speaker: "ai", text: res.say, callout: res.callout };
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
      if (res.shouldEnd || isFinalTurn) finishSession(newTurns, newConf);
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

  async function finishSession(finalTurns, conf) {
    setPhase("finished");
    track("complete", scenario.id);
    const verdict = await finalVerdict(scenario, finalTurns, conf);
    onFinish({ verdict, scenario, finalConfidence: conf });
  }

  // keep a ref of latest confidence for the async verdict call
  const confidenceRef = useRef(confidence);

  function submitUser(text) {
    const trimmed = text.trim();
    if (!trimmed) return;
    // Cut off any AI voice still playing so it doesn't talk over the user.
    if (audioRef.current) { try { audioRef.current.pause(); } catch { /* ignore */ } }
    setDraft("");
    const userTurn = { speaker: "user", text: trimmed, callout: null };
    const history = [...turns, userTurn];
    setTurns(history);
    setPhase("sending");
    runAITurn(history);
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
    partialBusyRef.current = false;
    lastPartialRef.current = "";
    setDraft("");
    const mr = new MediaRecorder(stream);
    mediaRecRef.current = mr;
    mr.ondataavailable = (e) => {
      if (e.data.size) chunksRef.current.push(e.data);
      // Pseudo-live: transcribe the audio-so-far and show it in the input bar.
      // Throttled to one request at a time so we never pile up calls.
      if (!partialBusyRef.current && chunksRef.current.length && mr.state === "recording") {
        partialBusyRef.current = true;
        const soFar = new Blob(chunksRef.current, { type: mr.mimeType || "audio/webm" });
        transcribe(soFar).then((text) => {
          partialBusyRef.current = false;
          if (text && mediaRecRef.current === mr && mr.state === "recording") {
            lastPartialRef.current = text;
            setDraft(text);
          }
        });
      }
    };
    mr.onstop = async () => {
      stream.getTracks().forEach((t) => t.stop());
      const blob = new Blob(chunksRef.current, { type: mr.mimeType || "audio/webm" });
      setPhase("transcribing");
      const text = (await transcribe(blob)) || lastPartialRef.current.trim();
      setDraft("");
      if (text) submitUser(text);
      else {
        setError("Couldn't catch that — try again or type.");
        setPhase("awaiting");
      }
    };
    setError(null);
    mr.start(2000); // emit a chunk every 2s -> drives the live transcript
    setPhase("recording");
  }

  const lastCallout = [...turns].reverse().find((t) => t.callout)?.callout;
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
      {lastCallout && phase !== "finished" && (
        <div className="callout fadein" key={lastCallout}>👀 {lastCallout}</div>
      )}
      {phase === "transcribing" && (
        <div className="bubble listening">transcribing…</div>
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
    <div className="df-micro" style={{ color: "var(--warning)" }}>{error}</div>
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

        <ConfidenceMeter value={confidence} />
        {transcriptEl}
        {errorEl}
        {inputEl}
      </div>
    </div>
  );
}

function clamp(v) {
  return Math.max(0, Math.min(1, v));
}
