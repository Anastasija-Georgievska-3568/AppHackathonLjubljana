import { useState } from "react";
import { submitFeedback, markDone } from "./feedback.js";

const QUESTIONS = [
  {
    key: "relevance",
    q: "How relevant was this scenario to you?",
    low: "not at all",
    high: "exactly my situation",
  },
  {
    key: "coachUsefulness",
    q: "How useful was the coaching feedback?",
    low: "useless",
    high: "genuinely helpful",
  },
  {
    key: "repeatIntent",
    q: "Next time you need to prep for a hard conversation, how likely are you to use this app?",
    low: "never",
    high: "definitely",
  },
];

export default function FeedbackModal({ context = {}, onClose }) {
  const [ratings, setRatings] = useState({});
  const [nativePref, setNativePref] = useState(null);
  const [nativeLanguage, setNativeLanguage] = useState("");
  const [text, setText] = useState("");
  const [email, setEmail] = useState("");
  const [sending, setSending] = useState(false);

  const canSend = QUESTIONS.every((q) => ratings[q.key]) && !sending;

  async function send() {
    setSending(true);
    await submitFeedback({
      ...ratings,
      nativePref: nativePref || "",
      nativeLanguage: nativePref === "yes" ? nativeLanguage : "",
      text,
      email,
      ...context,
    });
    markDone();
    onClose(true);
  }

  return (
    <div className="modal-overlay" onClick={() => onClose(false)}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="df-kicker">QUICK BETA FEEDBACK</div>
        <h2 className="df-title" style={{ marginTop: 6 }}>Help us make this better</h2>

        {QUESTIONS.map((qq) => (
          <div key={qq.key} style={{ marginTop: 16 }}>
            <div className="df-body" style={{ color: "var(--ink)", fontWeight: 700 }}>{qq.q}</div>
            <div className="rating-row">
              {[1, 2, 3, 4, 5].map((n) => (
                <button
                  key={n}
                  className={`rating-dot${ratings[qq.key] === n ? " on" : ""}`}
                  onClick={() => setRatings((r) => ({ ...r, [qq.key]: n }))}
                >
                  {n}
                </button>
              ))}
            </div>
            <div className="rating-ends">
              <span>{qq.low}</span>
              <span>{qq.high}</span>
            </div>
          </div>
        ))}

        <div style={{ marginTop: 16 }}>
          <div className="df-body" style={{ color: "var(--ink)", fontWeight: 700 }}>
            Would you prefer the app in your native language?
          </div>
          <div className="rating-row">
            <button
              className={`rating-dot${nativePref === "yes" ? " on" : ""}`}
              onClick={() => setNativePref("yes")}
            >
              Yes
            </button>
            <button
              className={`rating-dot${nativePref === "no" ? " on" : ""}`}
              onClick={() => setNativePref("no")}
            >
              No
            </button>
          </div>
          {nativePref === "yes" && (
            <input
              className="text-input"
              style={{ marginTop: 8, width: "100%" }}
              value={nativeLanguage}
              onChange={(e) => setNativeLanguage(e.target.value)}
              placeholder="which language?"
            />
          )}
        </div>

        <div style={{ marginTop: 16 }}>
          <div className="df-body" style={{ color: "var(--ink)", fontWeight: 700 }}>
            What would make this better?
          </div>
          <textarea
            className="text-input"
            style={{ marginTop: 6, width: "100%" }}
            rows={3}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="anything — bugs, ideas, what felt off…"
          />
        </div>

        <div style={{ marginTop: 12 }}>
          <input
            className="text-input"
            style={{ width: "100%" }}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="email (optional — if you're up for a follow-up)"
          />
        </div>

        <button
          className="btn primary block"
          style={{ marginTop: 18 }}
          disabled={!canSend}
          onClick={send}
        >
          {sending ? "Sending…" : "Send feedback"}
        </button>
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
