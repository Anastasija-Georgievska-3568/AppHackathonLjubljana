# Don't Fold — Web

The web version of Don't Fold. Same scenarios, same AI, same verdict cards as the
iOS app — it talks to the **same Cloudflare Worker proxy**
(`dontfold-proxy.dontfold.workers.dev`), so there's no separate backend.

## Run it

```bash
cd web
npm install
npm run dev          # http://localhost:5173
```

In dev, Vite proxies `/proxy/*` → the Worker, so there's no CORS to worry about.

## How it maps to the iOS app

| iOS (Swift)                     | Web                                  |
| ------------------------------- | ------------------------------------ |
| `GeminiService.swift` (prompts, schemas, JSON repair) | `src/api.js` |
| `ScenarioCatalog.swift`         | `src/scenarios.js`                   |
| `TextToSpeech` (OpenAI `/tts`)  | `src/api.js#fetchTTS` + `<audio>`    |
| `SpeechRecognizer` (SFSpeech)   | `src/speech.js` (Web Speech API)     |
| `Theme.swift` palette           | `src/theme.css`                      |
| SwiftUI screens                 | `App.jsx`, `Challenge.jsx`, `Result.jsx` |

## Voice notes

- **AI voice (TTS):** high-quality OpenAI `tts-1-hd` via the proxy — identical to iOS.
- **Your voice (speech-to-text):** browser Web Speech API. Great in Chrome/Edge,
  works in Safari with a tap. Where it's unavailable, the app falls back to a text box
  (also reachable any time via "or type instead").

## Deploy

The Worker now sends CORS headers, so a static deploy can call it directly.

1. **Redeploy the Worker once** (adds CORS — required for prod):
   ```bash
   cd ../proxy && npx wrangler deploy
   ```
2. **Build + host the static site** (e.g. Cloudflare Pages):
   ```bash
   cd ../web && npm run build      # outputs dist/
   npx wrangler pages deploy dist
   ```

> The app token is shipped in the client bundle — same as the iOS binary. Fine for a
> demo; rotate with `wrangler secret put APP_TOKEN` if it leaks.
