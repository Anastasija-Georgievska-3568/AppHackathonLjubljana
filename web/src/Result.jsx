import { Aurora } from "./components.jsx";

export default function Result({ result, onReplay, onHome, isDesktop }) {
  const { verdict, finalConfidence } = result;
  const score = verdict.finalConfidenceScore ?? Math.round(finalConfidence * 100);
  const tierColor =
    score >= 70 ? "var(--accent)" : score >= 40 ? "var(--accent2)" : "var(--warning)";

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
      <div className="df-kicker">YOUR VERDICT</div>
      <h1 className="df-display" style={{ margin: "8px 0" }}>{verdict.verdictTitle}</h1>
      <div className="score-ring" style={{ color: tierColor }}>{score}</div>
      <div className="df-micro" style={{ marginTop: 4 }}>CONFIDENCE / 100</div>
      {verdict.verdictVibe && (
        <p className="df-body" style={{ marginTop: 14 }}>{verdict.verdictVibe}</p>
      )}
    </div>
  );

  const shareCard = verdict.oneLinerToShare && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">SHAREABLE</div>
      <p className="df-title" style={{ marginTop: 6, fontSize: 18 }}>
        “{verdict.oneLinerToShare}”
      </p>
    </div>
  );

  const stats = verdict.stats?.length > 0 && (
    <div className="chip-grid">
      {verdict.stats.map((s, i) => (
        <div className="chip fadein" key={i}>
          <div className="df-micro">{s.label}</div>
          <div className="v">{s.value}</div>
          {s.detail && <div className="df-micro" style={{ marginTop: 2 }}>{s.detail}</div>}
        </div>
      ))}
    </div>
  );

  const good = verdict.goodMoments?.length > 0 && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">WHAT LANDED</div>
      {verdict.goodMoments.map((m, i) => (
        <div className="list-item" key={i}><span className="dot">✓</span><span>{m}</span></div>
      ))}
    </div>
  );

  const improve = verdict.improvementAreas?.length > 0 && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">NEXT TIME</div>
      {verdict.improvementAreas.map((m, i) => (
        <div className="list-item" key={i}><span className="dot">→</span><span>{m}</span></div>
      ))}
    </div>
  );

  const actions = (
    <>
      <button className="btn primary block" onClick={share}>Share my verdict</button>
      <div className="row">
        <button className="btn ghost block" onClick={onReplay}>Run it back</button>
        <button className="btn ghost block" onClick={onHome}>Home</button>
      </div>
    </>
  );

  if (isDesktop) {
    return (
      <div className="app-shell desk-shell">
        <Aurora intensity={score / 100} />
        <div className="desk">
          <aside className="aside">
            {hero}
            <div className="spacer" />
            {actions}
          </aside>
          <section className="main">
            {shareCard}
            {stats}
            {good}
            {improve}
          </section>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Aurora intensity={score / 100} />
      <div className="screen" style={{ position: "relative" }}>
        {hero}
        {shareCard}
        {stats}
        {good}
        {improve}
        <div className="spacer" />
        {actions}
      </div>
    </div>
  );
}
