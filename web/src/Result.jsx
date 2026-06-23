import { useEffect, useState } from "react";
import FeedbackModal from "./FeedbackModal.jsx";
import { markCompletedRun, shouldAutoPrompt } from "./feedback.js";

export default function Result({ result, onReplay, onHome }) {
  const { verdict } = result;
  const score = verdict.finalScore ?? 0;
  const band = verdict.band || "";

  const [showFeedback, setShowFeedback] = useState(false);
  useEffect(() => {
    const runs = markCompletedRun();
    if (!shouldAutoPrompt(runs)) return;
    // Let the verdict breathe: open ~10s after it shows, OR as soon as the user
    // interacts with the card (clicks anything that isn't an action button).
    let opened = false;
    const open = () => {
      if (opened) return;
      opened = true;
      setShowFeedback(true);
      cleanup();
    };
    const onClick = (e) => {
      if (e.target.closest("button, a, input, textarea")) return;
      open();
    };
    const timer = setTimeout(open, 10000);
    document.addEventListener("click", onClick, true);
    function cleanup() {
      clearTimeout(timer);
      document.removeEventListener("click", onClick, true);
    }
    return cleanup;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const feedbackContext = {
    scenario: result.scenario?.id || "",
    persona: result.scenario?.personaLabel || "",
    score,
    band,
  };
  const tierColor =
    score >= 80
      ? "var(--accent)"
      : score >= 60
      ? "var(--accent)"
      : score >= 40
      ? "var(--accent2)"
      : "var(--warning)";

  async function share() {
    const text = verdict.oneLinerToShare
      ? `${verdict.verdictTitle} — ${verdict.oneLinerToShare} (${score}/100) · Don't Fold`
      : `${verdict.verdictTitle} (${score}/100) · Don't Fold`;
    try {
      if (navigator.share) await navigator.share({ text });
      else {
        await navigator.clipboard.writeText(text);
        alert("Copied to clipboard ✨");
      }
    } catch {
      /* user cancelled */
    }
  }

  const hero = (
    <div className="card pink verdict-hero fadein">
      <div className="df-kicker">{band ? band.toUpperCase() : "YOUR VERDICT"}</div>
      <h1 className="df-display" style={{ margin: "8px 0" }}>{verdict.verdictTitle}</h1>
      <div className="score-ring" style={{ color: tierColor }}>{score}</div>
      <div className="df-micro" style={{ marginTop: 4 }}>CONFIDENCE / 100</div>
    </div>
  );

  const heldBest = verdict.heldBest && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">WHAT HELD</div>
      <p className="df-body" style={{ marginTop: 6 }}>{verdict.heldBest}</p>
    </div>
  );

  const leak = verdict.biggestLeakBetter && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker" style={{ color: "var(--warning)" }}>BIGGEST LEAK</div>
      {verdict.biggestLeakQuote && (
        <p className="df-body" style={{ marginTop: 6, fontStyle: "italic" }}>
          “{verdict.biggestLeakQuote}”
        </p>
      )}
      <p className="df-body" style={{ marginTop: 6 }}>
        <strong>Try:</strong> {verdict.biggestLeakBetter}
      </p>
    </div>
  );

  const practice = verdict.practice && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">PRACTICE THIS</div>
      <p className="df-body" style={{ marginTop: 6 }}>{verdict.practice}</p>
    </div>
  );

  const actions = (
    <>
      <button className="btn primary block" onClick={share}>Share my verdict</button>
      <div className="row">
        <button className="btn ghost block" onClick={onReplay}>Run it back</button>
        <button className="btn ghost block" onClick={onHome}>Home</button>
      </div>
      <button
        className="feedback-cta"
        onClick={() => setShowFeedback(true)}
      >
        💬 give feedback
      </button>
    </>
  );

  return (
    <div className="app-shell">
      <div className="screen">
        {hero}
        {heldBest}
        {leak}
        {practice}
        <div className="spacer" />
        {actions}
      </div>
      {showFeedback && (
        <FeedbackModal context={feedbackContext} onClose={() => setShowFeedback(false)} />
      )}
    </div>
  );
}
