import { useState } from "react";
import { SCENARIOS, resolveScenario } from "./scenarios.js";
import { Aurora } from "./components.jsx";
import { useIsDesktop } from "./useIsDesktop.js";
import Challenge from "./Challenge.jsx";
import Result from "./Result.jsx";

export default function App() {
  const [route, setRoute] = useState({ name: "home" });
  const isDesktop = useIsDesktop();

  switch (route.name) {
    case "personas":
      return (
        <PersonaPicker
          isDesktop={isDesktop}
          scenario={route.scenario}
          onBack={() => setRoute({ name: "home" })}
          onPick={(persona) =>
            setRoute({ name: "brief", scenario: resolveScenario(route.scenario, persona) })
          }
        />
      );
    case "brief":
      return (
        <Brief
          isDesktop={isDesktop}
          scenario={route.scenario}
          onBack={() => setRoute({ name: "home" })}
          onStart={() => setRoute({ name: "challenge", scenario: route.scenario })}
        />
      );
    case "challenge":
      return (
        <Challenge
          isDesktop={isDesktop}
          scenario={route.scenario}
          onExit={() => setRoute({ name: "home" })}
          onFinish={(result) => setRoute({ name: "result", result })}
        />
      );
    case "result":
      return (
        <Result
          isDesktop={isDesktop}
          result={route.result}
          onReplay={() => setRoute({ name: "challenge", scenario: route.result.scenario })}
          onHome={() => setRoute({ name: "home" })}
        />
      );
    default:
      return <Home isDesktop={isDesktop} onOpen={openScenario} />;
  }

  function openScenario(scenario) {
    if (scenario.comingSoon) return;
    if (scenario.personas?.length) setRoute({ name: "personas", scenario });
    else setRoute({ name: "brief", scenario });
  }
}

/* ---- shared presentational pieces (used by both layouts) ---- */

function ScenarioCard({ s, onOpen }) {
  return (
    <button
      className={`card scenario-card${s.comingSoon ? " locked" : ""}`}
      onClick={() => onOpen(s)}
    >
      <div className="row">
        <span className="tag soft">{s.personaTypeLabel || "scenario"}</span>
        {s.comingSoon && <span className="tag">🔒 coming soon</span>}
        {s.personas?.length > 0 && !s.comingSoon && (
          <span className="tag pink">{s.personas.length} personas</span>
        )}
      </div>
      <div className="df-title" style={{ marginTop: 4 }}>{s.title}</div>
      <div className="df-body">{s.blurb}</div>
    </button>
  );
}

function PersonaCard({ p, selected, onClick }) {
  return (
    <button
      className={`card persona-card${selected ? " selected" : ""}`}
      onClick={onClick}
    >
      <div className="df-title" style={{ fontSize: 17 }}>{p.label}</div>
      <div className="df-body" style={{ fontSize: 13, color: "inherit" }}>{p.description}</div>
      <div className="spacer" />
      <div className="weak">⚠ {p.weakpoint}</div>
    </button>
  );
}

function HeroIntro() {
  return (
    <>
      <div className="df-kicker">A GEN-Z PRESSURE TEST</div>
      <h1 className="df-display" style={{ marginTop: 8 }}>
        Don't<br />Fold.
      </h1>
      <p className="df-body" style={{ marginTop: 10 }}>
        Real-life moments that make you sweat. Hold your ground out loud — get a
        Wrapped-style read on whether you folded.
      </p>
    </>
  );
}

/* ---- Home ---- */

function Home({ isDesktop, onOpen }) {
  const list = SCENARIOS.map((s) => <ScenarioCard key={s.id} s={s} onOpen={onOpen} />);

  if (isDesktop) {
    return (
      <div className="app-shell desk-shell">
        <Aurora intensity={0.5} />
        <div className="desk desk--wide-aside">
          <aside className="aside">
            <HeroIntro />
            <div className="spacer" />
            <div className="df-micro">built for the room you're dreading</div>
          </aside>
          <section className="main">
            <div className="df-micro">CHOOSE YOUR PRESSURE</div>
            <div className="scenario-grid">{list}</div>
          </section>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Aurora intensity={0.5} />
      <div className="screen" style={{ position: "relative" }}>
        <div style={{ marginTop: 8 }}>
          <HeroIntro />
        </div>
        <div className="df-micro" style={{ marginTop: 8 }}>CHOOSE YOUR PRESSURE</div>
        {list}
        <div className="df-micro" style={{ textAlign: "center", marginTop: 8 }}>
          built for the room you're dreading
        </div>
      </div>
    </div>
  );
}

/* ---- Persona picker ---- */

function PersonaPicker({ isDesktop, scenario, onBack, onPick }) {
  const [selected, setSelected] = useState(null);
  const grid = (
    <div className="persona-grid">
      {scenario.personas.map((p) => (
        <PersonaCard
          key={p.id}
          p={p}
          selected={selected?.id === p.id}
          onClick={() => setSelected(p)}
        />
      ))}
    </div>
  );
  const cta = (
    <button className="btn primary block" disabled={!selected} onClick={() => onPick(selected)}>
      {selected ? `Face ${selected.label}` : "Select an opponent"}
    </button>
  );

  if (isDesktop) {
    return (
      <div className="app-shell desk-shell">
        <Aurora intensity={0.5} />
        <div className="desk">
          <aside className="aside">
            <div className="topbar">
              <button className="icon-btn" onClick={onBack}>←</button>
              <div className="df-micro">{scenario.title}</div>
            </div>
            <h1 className="df-display">Pick your<br />opponent.</h1>
            <p className="df-body">Each one breaks you a different way. Choose who you're up against.</p>
            <div className="spacer" />
            {cta}
          </aside>
          <section className="main">{grid}</section>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Aurora intensity={0.5} />
      <div className="screen" style={{ position: "relative" }}>
        <div className="topbar">
          <button className="icon-btn" onClick={onBack}>←</button>
          <div className="df-micro">{scenario.title}</div>
        </div>
        <h1 className="df-display">Pick your<br />opponent.</h1>
        <p className="df-body">Each one breaks you a different way. Choose who you're up against.</p>
        {grid}
        <div className="spacer" />
        {cta}
      </div>
    </div>
  );
}

/* ---- Brief ---- */

function Brief({ isDesktop, scenario, onBack, onStart }) {
  const sceneCard = (
    <div className="card pink" style={{ padding: 16 }}>
      <div className="df-kicker">THE SCENE</div>
      <p className="df-body" style={{ marginTop: 6 }}>{scenario.setup}</p>
    </div>
  );
  const personaCard = scenario.personaBrief && (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">
        {scenario.personaLabel ? scenario.personaLabel.toUpperCase() : "THE PERSONA"}
      </div>
      <p className="df-body" style={{ marginTop: 6 }}>{scenario.personaBrief}</p>
    </div>
  );
  const goalCard = (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker">YOUR GOAL</div>
      <p className="df-body" style={{ marginTop: 6 }}>{scenario.userGoal}</p>
    </div>
  );
  const avoidCard = (
    <div className="card" style={{ padding: 16 }}>
      <div className="df-kicker" style={{ color: "var(--warning)" }}>AVOID</div>
      {scenario.pressureCues.map((c, i) => (
        <div className="list-item" key={i}>
          <span className="dot" style={{ color: "var(--warning)" }}>✕</span>
          <span>{c}</span>
        </div>
      ))}
    </div>
  );
  const startBtn = (
    <button className="btn primary block" onClick={onStart}>I'm ready — start</button>
  );

  if (isDesktop) {
    return (
      <div className="app-shell desk-shell">
        <Aurora intensity={0.5} />
        <div className="desk">
          <aside className="aside">
            <div className="topbar">
              <button className="icon-btn" onClick={onBack}>←</button>
              <div className="df-micro">THE BRIEF</div>
            </div>
            <span className="tag soft">{scenario.personaTypeLabel || "scenario"}</span>
            <h1 className="df-display">{scenario.title}</h1>
            {sceneCard}
            <div className="spacer" />
            {startBtn}
          </aside>
          <section className="main">
            {personaCard}
            {goalCard}
            {avoidCard}
          </section>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Aurora intensity={0.5} />
      <div className="screen" style={{ position: "relative" }}>
        <div className="topbar">
          <button className="icon-btn" onClick={onBack}>←</button>
          <div className="df-micro">THE BRIEF</div>
        </div>
        <span className="tag soft">{scenario.personaTypeLabel || "scenario"}</span>
        <h1 className="df-display">{scenario.title}</h1>
        {sceneCard}
        {personaCard}
        {goalCard}
        {avoidCard}
        <div className="spacer" />
        {startBtn}
      </div>
    </div>
  );
}
