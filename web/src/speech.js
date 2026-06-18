// Thin wrapper over the browser Web Speech API (the web counterpart of
// SpeechRecognizer.swift). Live partial transcription, en-US.
// Chrome/Edge: solid. Safari: works but less reliable, requires a user gesture.

export function speechSupported() {
  return (
    typeof window !== "undefined" &&
    (window.SpeechRecognition || window.webkitSpeechRecognition)
  );
}

export function createRecognizer({ onPartial, onFinal, onEnd, onError } = {}) {
  const Impl = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Impl) return null;

  const rec = new Impl();
  rec.lang = "en-US";
  rec.continuous = true;
  rec.interimResults = true;

  let finalText = "";

  rec.onresult = (event) => {
    let interim = "";
    for (let i = event.resultIndex; i < event.results.length; i++) {
      const res = event.results[i];
      if (res.isFinal) finalText += res[0].transcript;
      else interim += res[0].transcript;
    }
    onPartial?.((finalText + " " + interim).trim());
  };
  rec.onerror = (e) => onError?.(e.error || "speech-error");
  rec.onend = () => {
    onFinal?.(finalText.trim());
    onEnd?.();
  };

  return {
    start() {
      finalText = "";
      try {
        rec.start();
      } catch {
        /* already started */
      }
    },
    stop() {
      try {
        rec.stop();
      } catch {
        /* not running */
      }
    },
  };
}
