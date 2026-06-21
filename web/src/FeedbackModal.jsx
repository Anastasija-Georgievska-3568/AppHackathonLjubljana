import { useState } from "react";
import { submitFeedback, markDone } from "./feedback.js";

// A short funnel: one card per step, progress bar so users see how long it is.
const STEPS = [
  {
    type: "select",
    key: "seniority",
    q: "Where are you in your career?",
    options: ["Junior", "Mid", "Senior"],
  },
  {
    type: "rating",
    key: "challenge",
    q: "Was the conversation challenging?",
    low: "too easy",
    high: "very challenging",
    followUpWhenLte: 3,
    followUpKey: "challengeMore",
    followUpPlaceholder: "what would make it more challenging?",
  },
  {
    type: "dual-rating",
    q: "How were the manager personas?",
    rows: [
      { key: "personasBelievable", label: "Exaggerated, but still believable?", low: "no", high: "totally" },
      { key: "personasUseful", label: "Useful to practice on?", low: "useless", high: "very useful" },
    ],
  },
  {
    type: "rating",
    key: "verdictAccuracy",
    q: "Did the verdict capture your real strengths and weak points?",
    low: "way off",
    high: "spot on",
  },
  {
    type: "rating-plus-text",
    key: "repeatIntent",
    q: "Next time you need to prep for a hard conversation, how likely are you to use this app?",
    low: "never",
    high: "definitely",
    textKey: "nextScenario",
    textPlaceholder: "which situation would you most want to practice next? (optional)",
  },
  { type: "wrap", q: "Last thing" },
];

export default function FeedbackModal({ context = {}, onClose }) {
  const [step, setStep] = useState(0);
  const [data, setData] = useState({}); // all answers keyed by field
  const [nativePref, setNativePref] = useState(null);
  const [sending, setSending] = useState(false);

  const s = STEPS[step];
  const isLast = step === STEPS.length - 1;
  const set = (key, val) => setData((d) => ({ ...d, [key]: val }));

  const canAdvance =
    s.type === "select"
      ? !!data[s.key]
      : s.type === "rating" || s.type === "rating-plus-text"
      ? !!data[s.key]
      : s.type === "dual-rating"
      ? s.rows.every((r) => data[r.key])
      : true; // wrap is optional

  async function finish() {
    setSending(true);
    await submitFeedback({
      ...data,
      nativePref: nativePref || "",
      nativeLanguage: nativePref === "yes" ? data.nativeLanguage || "" : "",
      ...context,
    });
    markDone();
    onClose(true);
  }

  function next() {
    if (isLast) finish();
    else setStep((i) => i + 1);
  }

  const Scale = ({ k, low, high }) => (
    <div style={{ marginTop: 8 }}>
      <div className="rating-row">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            className={`rating-dot${data[k] === n ? " on" : ""}`}
            onClick={() => set(k, n)}
          >
            {n}
          </button>
        ))}
      </div>
      <div className="rating-ends">
        <span>{low}</span>
        <span>{high}</span>
      </div>
    </div>
  );

  return (
    <div className="modal-overlay" onClick={() => onClose(false)}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="funnel-progress">
          <div
            className="funnel-progress-fill"
            style={{ width: `${((step + 1) / STEPS.length) * 100}%` }}
          />
        </div>
        <div className="df-micro" style={{ marginTop: 8 }}>{step + 1} of {STEPS.length}</div>

        <h2 className="df-title" style={{ marginTop: 12, minHeight: 52 }}>{s.q}</h2>

        {s.type === "select" && (
          <div className="rating-row" style={{ marginTop: 8 }}>
            {s.options.map((o) => (
              <button
                key={o}
                className={`rating-dot${data[s.key] === o ? " on" : ""}`}
                onClick={() => set(s.key, o)}
              >
                {o}
              </button>
            ))}
          </div>
        )}

        {s.type === "rating" && (
          <>
            <Scale k={s.key} low={s.low} high={s.high} />
            {s.followUpKey && data[s.key] && data[s.key] <= s.followUpWhenLte && (
              <textarea
                className="text-input"
                style={{ width: "100%", marginTop: 12 }}
                rows={2}
                value={data[s.followUpKey] || ""}
                onChange={(e) => set(s.followUpKey, e.target.value)}
                placeholder={s.followUpPlaceholder}
              />
            )}
          </>
        )}

        {s.type === "dual-rating" &&
          s.rows.map((r) => (
            <div key={r.key} style={{ marginTop: 14 }}>
              <div className="df-body" style={{ color: "var(--ink)", fontWeight: 700 }}>{r.label}</div>
              <Scale k={r.key} low={r.low} high={r.high} />
            </div>
          ))}

        {s.type === "rating-plus-text" && (
          <>
            <Scale k={s.key} low={s.low} high={s.high} />
            <textarea
              className="text-input"
              style={{ width: "100%", marginTop: 12 }}
              rows={2}
              value={data[s.textKey] || ""}
              onChange={(e) => set(s.textKey, e.target.value)}
              placeholder={s.textPlaceholder}
            />
          </>
        )}

        {s.type === "wrap" && (
          <div style={{ marginTop: 8 }}>
            <div className="df-body" style={{ color: "var(--ink)", fontWeight: 700 }}>
              Would you prefer the app in your native language?
            </div>
            <div className="rating-row" style={{ marginTop: 8 }}>
              <button className={`rating-dot${nativePref === "yes" ? " on" : ""}`} onClick={() => setNativePref("yes")}>Yes</button>
              <button className={`rating-dot${nativePref === "no" ? " on" : ""}`} onClick={() => setNativePref("no")}>No</button>
            </div>
            {nativePref === "yes" && (
              <input
                className="text-input"
                style={{ width: "100%", marginTop: 8 }}
                value={data.nativeLanguage || ""}
                onChange={(e) => set("nativeLanguage", e.target.value)}
                placeholder="which language?"
              />
            )}
            <textarea
              className="text-input"
              style={{ width: "100%", marginTop: 12 }}
              rows={2}
              value={data.text || ""}
              onChange={(e) => set("text", e.target.value)}
              placeholder="anything else? bugs, ideas, what felt off… (optional)"
            />
            <input
              className="text-input"
              style={{ width: "100%", marginTop: 10 }}
              type="email"
              value={data.email || ""}
              onChange={(e) => set("email", e.target.value)}
              placeholder="email (optional — if you're up for a follow-up)"
            />
            <div className="df-micro" style={{ marginTop: 10, opacity: 0.8 }}>
              Your answers (and email, if given) are stored to improve the app. See "privacy" on the home screen.
            </div>
          </div>
        )}

        <div className="row" style={{ marginTop: 20 }}>
          {step > 0 && (
            <button className="btn ghost" onClick={() => setStep((i) => i - 1)}>Back</button>
          )}
          <button className="btn primary block" disabled={!canAdvance || sending} onClick={next}>
            {isLast ? (sending ? "Sending…" : "Send feedback") : "Next"}
          </button>
        </div>

        <button
          className="df-micro"
          style={{ background: "none", border: "none", cursor: "pointer", marginTop: 10, width: "100%" }}
          onClick={() => onClose(false)}
        >
          not now
        </button>
      </div>
    </div>
  );
}
