// Short, plain-language privacy notice for the beta.
export default function PrivacyPolicy({ onClose }) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="df-kicker">PRIVACY</div>
        <h2 className="df-title" style={{ marginTop: 6 }}>What we collect (beta)</h2>

        <div className="df-body" style={{ marginTop: 12 }}>
          <p><strong>Your practice conversation.</strong> What you type or say in a session is
          sent to <strong>Google (Gemini)</strong> to generate the manager's replies and your
          coaching/score. If you use the mic, your audio is sent to <strong>OpenAI</strong> to
          turn speech into text and the AI's replies into voice. We don't store your
          conversations on our side.</p>

          <p style={{ marginTop: 10 }}><strong>Anonymous usage.</strong> A random id is stored in
          your browser so we don't re-ask for feedback; basic counts (sessions started/finished)
          are recorded. No account, no login.</p>

          <p style={{ marginTop: 10 }}><strong>Feedback you submit.</strong> Your ratings, any
          text, and an <em>optional</em> email are stored in our Google Sheet and Cloudflare to
          improve the app. Email is only used to follow up with you if you leave it.</p>

          <p style={{ marginTop: 10 }}>We don't sell your data. Beta data is kept only while the
          beta runs. Clear your browser storage to reset your anonymous id. Questions or removal
          requests: <strong>dontfold.app@gmail.com</strong>.</p>
        </div>

        <button className="btn primary block" style={{ marginTop: 18 }} onClick={onClose}>
          Got it
        </button>
      </div>
    </div>
  );
}
