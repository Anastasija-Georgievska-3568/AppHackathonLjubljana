import { useEffect, useRef, useState } from "react";
import { nextTurn, finalVerdict, fetchTTS, track } from "./api.js";
import { createRecognizer, speechSupported } from "./speech.js";
import { ConfidenceMeter, TypeOnText, MicButton, Aurora } from "./components.jsx";

const MAX_TURNS = 6;

export default function Challenge({ scenario, onFinish, onExit, isDesktop }) {
  const [turns, setTurns] = useState([]); // {speaker, text, callout}
  const [confidence, setConfidence] = useState(0.55);
  const [phase, setPhase] = useState("intro"); // intro | aiSpeaking | awaiting | recording | sending | finished
  const [partial, setPartial] = useState("");
  const [draft, setDraft] = useState("");
  const [typed, setTyped] = useState(false);
  const [error, setError] = useState(null);
  const [revealSpeed, setRevealSpeed] = useState(40); // ms per char for type-on

  const audioRef = useRef(null);
  const recRef = useRef(null);
  const transcriptEndRef = useRef(null);
  const startedRef = useRef(false);

  const userTurnCount = turns.filter((t) => t.speaker === "user").length;
  const supportsVoice = speechSupported();

  // Kick off with the AI's opening line.
  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;
    track("start", scenario.id);
    runAITurn([]);
    return () => {
      audioRef.current?.pause();
      recRef.current?.stop();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    transcriptEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [turns, partial]);

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
    setPartial("");
    setDraft("");
    const userTurn = { speaker: "user", text: trimmed, callout: null };
    const history = [...turns, userTurn];
    setTurns(history);
    setPhase("sending");
    runAITurn(history);
  }

  function toggleRecord() {
    if (phase === "recording") {
      recRef.current?.stop();
      return;
    }
    setPartial("");
    const rec = createRecognizer({
      onPartial: setPartial,
      onFinal: (finalText) => {
        setPhase("awaiting");
        if (finalText) submitUser(finalText);
      },
      onError: () => setPhase("awaiting"),
    });
    if (!rec) {
      setTyped(true);
      return;
    }
    recRef.current = rec;
    rec.start();
    setPhase("recording");
  }

  const lastCallout = [...turns].reverse().find((t) => t.callout)?.callout;
  const inputDisabled = phase === "sending" || phase === "aiSpeaking";

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
      {phase === "recording" && (
        <div className="bubble listening">{partial || "listening…"}</div>
      )}
      {(phase === "aiSpeaking" || phase === "sending") && (
        <div className="bubble ai thinking"><span>•</span><span>•</span><span>•</span></div>
      )}
      <div ref={transcriptEndRef} />
    </div>
  );

  const inputEl =
    phase === "finished" ? (
      <div className="df-micro" style={{ textAlign: "center" }}>scoring your round…</div>
    ) : typed || !supportsVoice ? (
      <div className="text-input-row">
        <textarea
          className="text-input"
          rows={2}
          placeholder="Type your response…"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              submitUser(draft);
            }
          }}
          disabled={inputDisabled}
        />
        <button className="btn primary" disabled={inputDisabled || !draft.trim()} onClick={() => submitUser(draft)}>
          Send
        </button>
      </div>
    ) : (
      <div className="mic-zone">
        <MicButton recording={phase === "recording"} disabled={inputDisabled} onClick={toggleRecord} />
        <button className="df-micro" style={{ background: "none", border: "none", cursor: "pointer" }} onClick={() => setTyped(true)}>
          or type instead
        </button>
      </div>
    );

  const errorEl = error && (
    <div className="df-micro" style={{ color: "var(--warning)" }}>{error}</div>
  );

  if (isDesktop) {
    return (
      <div className="app-shell desk-shell">
        <Aurora intensity={1 - confidence} />
        <div className="desk">
          <aside className="aside">
            <div className="topbar">
              <button className="icon-btn" onClick={onExit}>←</button>
              <div className="df-micro">THE ROOM</div>
              <div className="spacer" />
              {turnsBadge}
            </div>
            <span className="tag soft">{scenario.personaLabel || scenario.personaTypeLabel}</span>
            <h1 className="df-display" style={{ fontSize: 30 }}>{scenario.title}</h1>
            <div className="card pink" style={{ padding: 16 }}>
              <div className="df-kicker">THE SCENE</div>
              <p className="df-body" style={{ marginTop: 6 }}>{scenario.setup}</p>
            </div>
            <div className="card" style={{ padding: 16 }}>
              <div className="df-kicker">YOUR GOAL</div>
              <p className="df-body" style={{ marginTop: 6 }}>{scenario.userGoal}</p>
            </div>
            <div className="spacer" />
            <ConfidenceMeter value={confidence} />
          </aside>
          <section className="main">
            {transcriptEl}
            {errorEl}
            {inputEl}
          </section>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Aurora intensity={1 - confidence} />
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
