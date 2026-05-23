# Don't Fold

A Gen Z-style AI pressure-test for awkward real-life moments. Voice-driven scenarios (job interviews, asking for a raise, calling the doctor, sending back wrong food). Live pressure + confidence meters. Wrapped-style verdict cards built for screenshots.

## Run it

```bash
# 1. Open in Xcode
open DontFold.xcodeproj

# 2. In Xcode: pick an iPhone simulator → ⌘R
```

Or from the terminal:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project DontFold.xcodeproj -scheme DontFold \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro Max" \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

> The app runs with no API key — it falls back to a built-in mock AI that still drives the meters, callouts, and verdict cards so you can demo the whole flow.

## Wiring up real AI (Gemini)

The app calls Google Gemini (`gemini-2.5-flash`) with structured-JSON output. To enable real AI:

1. Get a key from [aistudio.google.com](https://aistudio.google.com).
2. Pick one of these three setup options:
   - **Easiest (dev):** drop the key into `~/Documents/dontfold_gemini_key.txt` on the simulator. (When running on the iOS Simulator, this file lives inside the simulator's app sandbox — easiest to set this with a one-time `print`/file copy step.) For real device builds, prefer one of the other two.
   - **Env var:** set `GEMINI_API_KEY` in the Xcode scheme (Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables).
   - **Info.plist:** add a `GEMINI_API_KEY` string key in `DontFold/Resources/Info.plist` (don't commit this).

Where the lookup happens: `DontFold/Services/GeminiConfig.swift`.

## Architecture

```
DontFold/
├── App/          DontFoldApp, RootView, Router
├── Design/       Theme, typography, gradients, glass card, meters, type-on text, mic button
├── Models/       Scenario, ScenarioCatalog, ChallengeSession, SessionResult
├── Services/     GeminiService + MockGemini, SpeechRecognizer, TextToSpeech, TranscriptAnalyzer
├── Screens/      Home, ScenarioList, ScenarioDetail, Challenge, Result, ShareCard
└── Resources/    Info.plist, Assets.xcassets
```

### AI loop (the interesting part)

Each turn round-trips `GeminiService.nextTurn(scenario:history:)`. The model is constrained to a JSON schema via Gemini's `responseSchema`:

```jsonc
{
  "say": "next in-character line, 1-2 sentences",
  "pressureDelta": -20..30,        // bumps the pressure meter
  "confidenceDelta": -30..20,      // bumps the confidence meter
  "callout": "optional Gen-Z sass observation — null if user did fine",
  "shouldEnd": false               // true when the scene wraps
}
```

At the end (or after `maxTurns = 8`), `finalVerdict(...)` produces a recap card with:
- a 2–4 word verdict title (e.g. *Recovering People Pleaser*),
- a one-line vibe summary,
- a shareable one-liner,
- 2–4 highlight moments,
- 3–4 stat chips.

System prompts live at the bottom of `GeminiService.swift`. Each `Scenario` ships its own persona, scene setup, user goal, and lists of pressure/confidence cues — those get merged into the system prompt at request time, so adding a new scenario is just adding an entry in `ScenarioCatalog.swift`.

### Voice I/O

- `SpeechRecognizer` wraps `SFSpeechRecognizer` + `AVAudioEngine` for live transcription with partial results streamed into the listening bubble.
- `TextToSpeech` wraps `AVSpeechSynthesizer` with a per-scenario `voiceHint` so different personas sound different.

### Design system

- `Theme.swift` — color tokens (hot pink, violet, electric cyan, dark background)
- `DFFont` — rounded heavy display / title / headline / body / micro / mono
- `GlassCard` — ultra-thin material + double-stroke
- `AnimatedAuroraBackground` — soft drifting blobs, intensity scales with pressure on the challenge screen
- `PressureMeter` / `ConfidenceMeter` — animated, color-shifting, glow at high values
- `MicButton` — pulsing rings when listening
- `TypeOnText` — character-by-character reveal for AI dialogue

## Adding a new scenario

Edit `DontFold/Models/ScenarioCatalog.swift`:

```swift
Scenario(
    id: "unique-id",
    title: "Title shown on cards",
    blurb: "One-liner for the row card",
    setup: "Longer scene-setting paragraph",
    category: .career,           // or .money, .life, .phone, .social, .food
    difficulty: .spicy,          // .mild, .spicy, .brutal
    aiPersona: "Who the AI is playing + how they behave",
    aiVoiceHint: "warm | clipped | calm | casual",
    openingLine: "AI's first spoken line",
    userGoal: "What the user is trying to accomplish",
    pressureCues: ["things that should crank pressure"],
    confidenceCues: ["things that should boost confidence"]
)
```

The cues get baked into the system prompt so the AI scores accordingly.

## Notes

- iOS 17+ (uses `@Observable`, `ContentTransition.numericText`, etc.)
- Portrait only, dark mode forced (it's the vibe)
- The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen). Regenerate with `xcodegen generate`.
- Mic/speech use NSMicrophoneUsageDescription + NSSpeechRecognitionUsageDescription, both already wired in `project.yml`.
