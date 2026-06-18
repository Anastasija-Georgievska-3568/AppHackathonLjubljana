import { useEffect, useRef, useState } from "react";

// Confidence meter — color shifts hot-pink with value (mirrors ConfidenceMeter.swift).
export function ConfidenceMeter({ value }) {
  const pct = Math.round(value * 100);
  const color =
    value < 0.4 ? "var(--warning)" : value < 0.7 ? "var(--accent2)" : "var(--accent)";
  return (
    <div className="meter-wrap">
      <div className="row" style={{ justifyContent: "space-between", marginBottom: 6 }}>
        <span className="df-micro">CONFIDENCE</span>
        <span className="df-micro" style={{ color }}>{pct}</span>
      </div>
      <div className="meter-track">
        <div className="meter-fill" style={{ width: `${pct}%`, background: color }} />
      </div>
    </div>
  );
}

// Character-by-character reveal for AI dialogue (TypeOnText.swift).
export function TypeOnText({ text, speed = 18, onDone }) {
  const [shown, setShown] = useState("");
  const doneRef = useRef(onDone);
  doneRef.current = onDone;
  useEffect(() => {
    setShown("");
    if (!text) return;
    let i = 0;
    const id = setInterval(() => {
      i++;
      setShown(text.slice(0, i));
      if (i >= text.length) {
        clearInterval(id);
        doneRef.current?.();
      }
    }, speed);
    return () => clearInterval(id);
  }, [text, speed]);
  return <span>{shown}</span>;
}

export function MicButton({ recording, disabled, onClick }) {
  return (
    <button
      className={`mic-btn${recording ? " recording" : ""}`}
      onClick={onClick}
      disabled={disabled}
      aria-label={recording ? "Stop" : "Speak"}
    >
      {recording ? "■" : "🎤"}
    </button>
  );
}

export function Aurora({ intensity = 0.4 }) {
  const o = 0.35 + intensity * 0.4;
  return (
    <div className="aurora">
      <div
        className="blob"
        style={{ width: 200, height: 200, top: -40, left: -30, background: "var(--accent2)", opacity: o }}
      />
      <div
        className="blob"
        style={{ width: 240, height: 240, bottom: -60, right: -50, background: "var(--accent3)", opacity: o, animationDelay: "1.5s" }}
      />
      <div
        className="blob"
        style={{ width: 160, height: 160, top: "40%", left: "55%", background: "var(--accent)", opacity: o * 0.6, animationDelay: "3s" }}
      />
    </div>
  );
}
