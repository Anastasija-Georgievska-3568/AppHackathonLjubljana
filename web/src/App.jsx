import { useState } from "react";
import { SCENARIOS, resolveScenario } from "./scenarios.js";
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
      return <Home onOpen={openScenario} />;
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
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 8 }}>
        <div className="df-title">{s.title}</div>
        {s.comingSoon
          ? <span className="df-kicker" style={{ color: "var(--accent)", marginTop: 3, whiteSpace: "nowrap" }}>COMING SOON</span>
          : <span style={{ color: "var(--accent)", fontSize: 22, fontWeight: 900, lineHeight: 1 }}>↗</span>
        }
      </div>
      <div className="df-body">{s.blurb}</div>
      {s.personas?.length > 0 && !s.comingSoon && (
        <div className="df-micro" style={{ color: "var(--accent)", marginTop: 4 }}>
          {s.personas.length} {(s.personaTypeLabel || "scenario").toUpperCase()} PERSONAS
        </div>
      )}
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
    </button>
  );
}

function HeroIntro() {
  return (
    <>
      <h1 className="df-display wordmark" style={{ marginBottom: 8 }}>
        DON'T<br />
        <span style={{ color: "var(--accent)" }}>FOLD.</span>
      </h1>
      <div className="df-kicker" style={{ color: "var(--ink)" }}>CHOOSE YOUR HARD CONVO →</div>
    </>
  );
}

/* ---- Home ---- */

function Home({ onOpen }) {
  return (
    <div className="app-shell">
      <div className="screen">
        <HeroIntro />
        <div className="scenario-grid">
          {SCENARIOS.map((s) => <ScenarioCard key={s.id} s={s} onOpen={onOpen} />)}
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

  return (
    <div className="app-shell">
      <div className="screen">
        <div className="topbar">
          <button className="icon-btn" onClick={onBack}>←</button>
          <div className="df-micro">{scenario.title}</div>
        </div>
        <h1 className="df-display">Pick your<br />opponent.</h1>
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

  return (
    <div className="app-shell">
      <div className="screen">
        <div className="topbar">
          <button className="icon-btn" onClick={onBack}>←</button>
          <div className="df-micro">THE BRIEF</div>
        </div>
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
