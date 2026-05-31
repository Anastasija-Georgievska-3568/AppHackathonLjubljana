# Handoff: Don't Fold — "Hot Girl CEO" Direction

## Overview
**Don't Fold** is a confidence-training app for hard conversations. Users pick a real-life
high-pressure scenario (asking for a raise, saying no to bridesmaid duty, ending a
situationship, etc.), read a short brief, then rehearse the conversation live against a
simulated counterpart who pushes back. They're scored on how well they hold their ground,
and walk away with a shareable "result card."

This handoff covers **one of three explored aesthetic directions: "Hot Girl CEO."** It is the
bold, high-contrast option — black ink, hot-pink accent, oversized display type, and
hand-scribbled affirmations. Energy: she's on her way to a meeting and you're in it.

The product is a girl-coded remix of an original gender-neutral concept. The *engine* is
unchanged (scenario → brief → live conversation → result); the scenarios and tone are the remix.

## About the Design Files
The files in this bundle are **design references created in HTML** — wireframe prototypes
showing intended structure, content, and behavior. They are **not production code to copy
directly.**

The task is to **recreate these designs in the target codebase's existing environment**
(React, Vue, SwiftUI, native, etc.) using its established patterns, component library, and
conventions. If no environment exists yet, choose the most appropriate framework for a
mobile-first app and implement there.

The prototype is a single pannable "design canvas" containing all explored directions. **Only
the section labeled "① HOT GIRL CEO" is in scope for this handoff.** Ignore the Soft Power and
Brat Mode sections. The relevant React components live in `screens.jsx` (`D1Home`, `D1Detail`,
`D1Convo`, `D1Result`) and the `.d1 { ... }` CSS block in the HTML file's `<style>`.

## Fidelity
**Low-fidelity (lofi).** These are wireframes. They establish:
- Screen inventory and flow
- Layout structure and content hierarchy
- Copy / tone of voice
- The intended aesthetic direction (color accent, type personality, scribble motifs)

They are **not** pixel-perfect. Use them as the source of truth for **structure, content, and
flow**, and for the **aesthetic intent** described in Design Tokens below. Apply the target
codebase's real spacing/elevation system and production-grade polish when building. Where the
wireframe shows a placeholder hand-drawn box, treat it as "a card goes here," not as a final
visual.

---

## Screens / Views

The flow is linear: **Home → Brief → Live Conversation → Result.** All screens are mobile
(designed in a ~280×580 phone frame; build responsive, mobile-first).

### 1. Home
- **Purpose:** User browses scenarios and picks one to rehearse.
- **Layout (top → bottom):**
  - Status row: tiny eyebrow label `01 · HOME` left, settings glyph right.
  - Hero wordmark: `DON'T` / `FOLD.` stacked — "DON'T" in ink, "FOLD." in hot pink. Large
    bold display, ~38px, tight tracking, line-height ~0.9. A handwritten tag `♡ girlies
    edition` sits rotated near the top-right of the hero.
  - Eyebrow prompt: `PICK YOUR HARD CONVO →`
  - **Scenario list** — vertical stack of cards (gap ~8px). Each card:
    - Title (bold, ~15px) + a circular pink chip with `↗` on the right.
    - One-line subtitle describing the scene (~12px).
    - The first/active card uses the soft-pink fill (`--soft`); others are cream with ink border.
  - Footer pinned to bottom: a black streak chip (`🔥 5-day streak`) left, a rotated pink
    handwritten quote (`"don't be normal"`) right.
- **Scenario content (exact copy):**
  | Title | Subtitle |
  |---|---|
  | Asking For A Raise | Boss said 'so… what did you want to talk about?' |
  | Telling Mom You're Moving | She thinks you're 'coming home for a bit'. You're not. |
  | Hard Convo With Him | He texted 'wyd'. It's been three weeks. |
  | Saying No To Bridesmaid | Dress is $480. Bachelorette is in Tulum. You're broke. |
  | Sephora Refund Drama | They sent the wrong shade. Twice. |

### 2. Brief
- **Purpose:** Frame the scenario and set the win condition before the user starts.
- **Layout:**
  - Status row: `02 · BRIEF` left, pink `×` close chip right.
  - Title block: eyebrow `SCENARIO 04` (pink), then headline `Saying No To` / `Bridesmaid
    Duty.` ("Bridesmaid Duty." in pink), ~26px.
  - Three stacked cards (gap ~10px):
    1. **Your goal** (pink-fill card): "Decline without apologising, hedging, or offering a
       cheaper version of yes."
    2. **The scene:** "It's your college roommate. The dress is $480, the bachelorette is in
       Tulum, and she's about to FaceTime you 'just to chat'."
    3. **⚠ Avoid this** (eyebrow in pink): bulleted list —
       - "I'll think about it"
       - "things have been crazy"
       - inventing a wedding to skip it
       - half-yes
  - Footer pinned bottom: full-width pink-fill CTA card, centered: `START → hold the line`.

### 3. Live Conversation
- **Purpose:** The core rehearsal. A chat thread where the counterpart pushes back and the
  user must hold their position. Real-time pressure/confidence meters react to each turn.
- **Layout:**
  - Header: left column — eyebrow `LIVE · TURN 3/8` and bold title `Bridesmaid Duty`; right —
    `×` chip.
  - **Two meters** side by side:
    - `PRESSURE` — segmented bar (5 segments), pink, 3 filled.
    - `CONFIDENCE` — segmented bar (5 segments), ink, 2 filled.
  - **Chat thread** (gap ~8px), alternating bubbles:
    - *Them* (left): avatar dot (pink) + gray bubble. e.g. "babe i literally can't get married
      without you 😭 it's just one dress"
    - *You* (right): pink bubble, white text. e.g. "I'm so honoured. I'm not going to be able
      to do it."
    - *Them:* "wait what?? is it the money i can help with the dress"
    - *You* (composing): dashed-border light-pink bubble showing "...typing"
  - Footer input bar pinned bottom: a dashed pill text field ("type if speaking feels like too
    much…") + a circular pink mic button on the right. **Voice is the primary input; text is
    the fallback.**

### 4. Result
- **Purpose:** Payoff + shareable card. Recaps performance and invites a repeat / share.
- **Layout:**
  - Status row: `10 · RESULT` left, `SHARE ↗` right.
  - Centered hero: eyebrow `YOUR DROP · 24 MAY 2026` (pink), big `DON'T` / `FOLD.` wordmark
    (~44px), eyebrow `BRIDESMAID DUTY` beneath.
  - **Verdict card** (pink-fill, centered): eyebrow `VERDICT`, then `HOT GIRL` / `HELD HER
    GROUND` in bold pink, ~24px.
  - **Two stat cards** side by side: `PRESSURE 62` (ink) and `CONFIDENCE 88` (pink-fill,
    emphasized). Numbers ~30px bold.
  - Footer pinned bottom: full-width card, centered: `SAVE IMAGE ✦ POST IT ✦ AGAIN`.

---

## Interactions & Behavior
- **Navigation:** Home card tap → Brief; Brief `START` → Live; Live completion → Result;
  Result `AGAIN` → restart the same scenario; `×` chips dismiss back one level.
- **Live conversation loop:** Turn-based (header shows `TURN n/8`). Each user reply advances
  the turn and recomputes both meters. The counterpart's next message is generated in response.
  Build the counterpart replies against whatever conversational/LLM backend the codebase uses;
  the wireframe copy is representative, not a fixed script.
- **Meters:** `PRESSURE` rises when the user hedges/apologizes/concedes; `CONFIDENCE` rises
  when they hold the line cleanly. Final values feed the Result screen. (Exact scoring math is
  product logic — not specified here; treat the wireframe numbers as illustrative.)
- **Input:** Mic is the hero control (press-to-speak); the text field is an always-available
  fallback. A "composing/typing" bubble appears while the counterpart or transcription resolves.
- **Result card sharing:** The result card is the shareable artifact — design it to export
  cleanly to an Instagram-Story / vertical 9:16 aspect (this is a TBD, see Open Questions).
- **Animation intent:** Meters animate on change; bubbles enter with a subtle slide/fade;
  result wordmark can have a small celebratory beat. Keep it snappy, not bouncy. Use the target
  codebase's standard motion tokens.

## State Management
Minimum state needed:
- `currentScreen` / route: `home | brief | live | result`
- `selectedScenario` (id → title, subtitle, goal, scene, avoid-list)
- Conversation: `messages[]` (role: them/you, text, status: sent/composing), `turn` (1–8)
- Meters: `pressure` (0–100), `confidence` (0–100)
- `streak` (days), `lastResult` (verdict string + final pressure/confidence + transcript
  receipts) for the Result + share card
- Data: scenario library (static/config); counterpart replies (generated per turn via backend)

## Design Tokens

> These are the wireframe's intent values for the **Hot Girl CEO** direction. Map them onto the
> target codebase's token system rather than hard-coding.

**Colors**
| Token | Hex | Use |
|---|---|---|
| Ink (text/borders) | `#0d0d0d` | Primary text, borders, dark chips |
| Background / cream | `#fffdf7` | App surface, card fills |
| Hot pink (accent) | `#ff2d87` | Accent text, primary CTAs, active chips, "you" bubbles |
| Soft pink | `#ffe6f0` | Highlighted/active card fills |
| Body text muted | `#33312d` | Card subtitles |
| Bubble gray (them) | `#f0f0f0` | Counterpart message bubbles |

**Typography** (web wireframe used these Google Fonts as stand-ins — substitute the codebase's
equivalents preserving the *personality*: a heavy geometric display + a casual hand + a mono):
- **Display / headlines / numbers:** `Bricolage Grotesque`, weight 800, tight tracking
  (~-0.5px to -1px), line-height ~0.85–0.95. Used for the wordmark, card titles, big stats.
- **Body / subtitles / handwritten tags:** `Patrick Hand` (casual) for body; `Caveat` /
  `Permanent Marker` for the rotated scribble affirmations.
- **Eyebrows / labels / meters / dates:** `Space Mono`, ~9px, letter-spacing ~0.15em, UPPERCASE.

**Spacing / radius / elevation**
- Card padding: ~10–12px. Inter-card gap: 8–10px. Screen padding: ~14–16px.
- Border radius: cards ~12px, chips/pills 99px (fully round), mic button circular.
- Borders: 1.5–2px solid ink (this direction leans on hard outlines, not shadows).
- Offset "sticker" shadow on the phone frame only (`3px 3px 0 ink`) — a flat, hard-edged
  shadow, not a soft blur. Use sparingly if at all in production.

**Motifs (the "badass girlies" flavor)**
- Rotated handwritten affirmations as accents (`♡ girlies edition`, `"don't be normal"`).
- Hard-outlined cards + flat offset shadows (sticker aesthetic).
- Hot-pink as a punch color against near-black + cream, never pastel-soft overall.

## Assets
- **No raster/vector assets** in the wireframe — all glyphs are Unicode (`↗ × ✦ ♡ 🔥`) and
  emoji. In production, replace `↗ × ✦` with the codebase's icon set; the `🔥` streak and 😭
  emoji in counterpart copy are intentional and should stay as emoji.
- **Fonts** are Google Fonts placeholders (see Typography) — swap for licensed/brand
  equivalents that match the personality.

## Files
- `Dont Fold - Girlies Wireframes.html` — the prototype shell. The `.d1 { ... }` block in
  `<style>` holds all Hot Girl CEO styling tokens.
- `screens.jsx` — React components. **In scope:** `D1Home`, `D1Detail`, `D1Convo`, `D1Result`,
  and the shared `Phone` wrapper + `Scenarios` data array near the top. (`D2*`/`D3*` are the
  other two directions — out of scope.)
- `design-canvas.jsx` — the pan/zoom canvas harness used to present the wireframes. **Not part
  of the product** — purely a viewer; ignore when implementing.

Open the HTML file in a browser to see all four screens laid out side by side under the
"① HOT GIRL CEO" section.

## Open Questions (carry-overs to resolve with the designer)
- **Name:** keep "Don't Fold." or rename?
- **Scenario spice level:** how far does the library go (situationship breakups, family
  boundaries, calling out a friend)?
- **Voice vs text:** is the mic truly the hero, or text-first with voice as a flex?
- **Share format:** result cards as 9:16 Instagram-Story / TikTok-overlay shaped?
- **Scoring labels:** keep "pressure / confidence" or rename ("nerve / nerve held",
  "pressure / poise")?
