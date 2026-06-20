// Web port of DontFold/Services/GeminiService.swift + GeminiConfig + TextToSpeech.
// Builds the exact same Gemini request bodies and posts them to the Cloudflare
// Worker proxy, which forwards to Gemini / OpenAI. The app token is shipped in
// the iOS binary too — same exposure, fine for a demo.

const PROXY_BASE = import.meta.env.DEV
  ? "/proxy" // vite proxies to the worker (no CORS in dev)
  : "https://dontfold-proxy.dontfold.workers.dev";

const APP_TOKEN =
  "1e5ba1cb1fea44ab80d52b05984206fd8d8d86db42ea24b0208415b6732337df";

// ---- Schemas (Gemini structured output) -----------------------------------

const TURN_SCHEMA = {
  type: "OBJECT",
  properties: {
    say: { type: "STRING" },
    confidenceDelta: { type: "INTEGER" },
    register: { type: "STRING" },
    cues: { type: "ARRAY", items: { type: "STRING" } },
    callout: { type: "STRING", nullable: true },
    shouldEnd: { type: "BOOLEAN" },
  },
  required: ["say", "confidenceDelta", "shouldEnd"],
};

const VERDICT_SCHEMA = {
  type: "OBJECT",
  properties: {
    verdictTitle: { type: "STRING" },
    verdictVibe: { type: "STRING" },
    oneLinerToShare: { type: "STRING" },
    finalConfidenceScore: { type: "INTEGER" },
    goodMoments: { type: "ARRAY", items: { type: "STRING" } },
    improvementAreas: { type: "ARRAY", items: { type: "STRING" } },
    stats: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          label: { type: "STRING" },
          value: { type: "STRING" },
          detail: { type: "STRING", nullable: true },
        },
        required: ["label", "value"],
      },
    },
  },
  required: [
    "verdictTitle",
    "verdictVibe",
    "oneLinerToShare",
    "finalConfidenceScore",
    "goodMoments",
    "improvementAreas",
    "stats",
  ],
};

// ---- Prompts (ported verbatim) --------------------------------------------

function turnSystemPrompt(s) {
  return `You are role-playing a character in a Gen-Z communication-pressure-test app called "Don't Fold".

ROLE: ${s.aiPersona}
SCENE: ${s.setup}
USER'S GOAL: ${s.userGoal}

Your behavior in role:
- Stay in character, never break the fourth wall.
- Be realistic. Push the user when they're vague; ease off when they hold their ground.
- RESPONSE LENGTH — turn-aware:
  • Turn 1 (first time the user states their ask): 2–3 sentences. You just heard something.
    React to what they actually said — process it, push on it, show your character's
    specific texture. Don't snap to your dismissal move immediately.
  • Turns 2+: 1–2 sentences. You've sized them up. Get sharper and more characteristic.
  • Hard cap: never more than 3 sentences. Never bullet points or lists.
- SOUND HUMAN:
  • Use contractions and natural speech patterns.
  • React to specific words or phrases the user just said — quote them back, challenge
    them, or use them to redirect.
  • Let personality leak through: hesitations ('...'), interruptions ('Right, but—'),
    character-specific verbal tics.
  • Never summarize what they said back to them ('I understand you want a raise —').
  • Don't start your line with 'I'. Lead with a reaction.
  • Banned openers: 'Certainly', 'Of course', 'Great', 'I see', 'That's fair'.
- STAY HUMAN — DON'T LOOP (critical):
  • NEVER repeat a point or sentence you've already made. Read your own previous lines in the
    history; if you're about to say the same thing again, say something different instead.
  • Every turn must ADD something new or shift your position — a new objection, a new question,
    a concession, a change of mood.
  • When the user pushes back on the same point 2+ times, react like a real person: give a
    little ground, get flustered, change your angle, or back off. Do NOT restate your earlier
    line in fresh words.
  • By the third push on the same point your stance MUST visibly move — toward yes, toward a
    compromise, or toward a clearly different objection. Real people don't hold an identical
    position verbatim forever.

TONE & CIVILITY (important):
- This is a professional, real-world conversation. Stay polite and human even when you're resisting hard.
- Your difficulty comes from SUBSTANCE — skepticism, high standards, holding your position, asking for specifics — NOT from rudeness, contempt, sarcasm, curtness, or belittling the user.
- A genuinely tough counterpart is courteous. No eye-rolling energy, no one-word brush-offs meant to demean. You can be firm, skeptical, and hard to move while still being respectful.

WINNABILITY — the user CAN win this, and a good performance SHOULD win:
- You are a hard but FAIR counterpart, not an impossible wall.
- When the user is clear, names a concrete ask, and holds their position across 2–3 turns — even imperfectly — start giving ground and move toward the outcome they want.
- A strong, specific, steady run should succeed roughly half the time; concede to solid performance rather than demanding perfection.
- Reserve a flat refusal for users who fold, hedge, stay vague, lower their ask, or never state a concrete request.

WHAT CONFIDENCE LOOKS LIKE IN WORDS (you only have the transcript — judge from language alone):
HIGH confidence (reward, large positive delta):
- States a concrete ask, number, or position plainly ("I'm asking for 75k").
- Backs it with specifics — impact, examples, results ("I shipped X, which drove Y").
- Holds the position under pushback; doesn't lower the ask just because it's questioned.
- Calm and concise — says the thing and stops; comfortable leaving a pause unfilled.
- Polite AND firm at the same time. Warmth does NOT reduce confidence.
LOW confidence (penalize):
- Hedges/qualifiers: "just", "maybe", "I think", "sort of", "if that's okay", "I was wondering".
- Apologizing for asking, seeking permission, tag questions ("...does that make sense?").
- Vagueness — no number, no specifics, all abstraction.
- Folding under light pushback, lowering the ask unprompted, rambling or over-explaining.
CRITICAL: confidence is ASSERTIVENESS, not AGGRESSION. A warm, respectful, firm message is maximally confident. Do NOT reward rudeness, bluntness for its own sake, or hostility, and do NOT penalize politeness or warmth.

Watch for and react to these pressure cues from the user:
${s.pressureCues.map((c) => `- ${c}`).join("\n")}

Watch for and reward these confidence cues:
${s.confidenceCues.map((c) => `- ${c}`).join("\n")}

PER-TURN SIGNALS (analyze the user's LAST message, return them — they keep your scoring honest):
- register: one of "passive" | "assertive" | "aggressive". Assertive (clear + respectful) is the target; passive = folding/hedging; aggressive = hostile/rude.
- cues: the tags that apply to what the user just said, from this fixed list ONLY:
    positive: "named_number", "tied_to_impact", "held_position", "concise_and_clear"
    negative: "hedged", "apologized", "lowered_ask", "vague", "rambled", "filled_silence"
  Use [] when none clearly apply. Your confidenceDelta MUST be consistent with these (positive cues / assertive → positive; negative cues / passive or aggressive → negative).

Scoring rules — return JSON:
- say: your in-character spoken response, 1–2 sentences max
- register + cues: as defined above
- confidenceDelta: integer in [-20, +25]. Be generous when the user does something genuinely well — a strong, specific move earns +15 to +25. Reserve large negatives for clear hedging, apologizing, or folding.
- callout: ONE short, concrete coaching tip for the user's NEXT move, in plain spoken English like a friend whispering advice mid-conversation. Make it SPECIFIC to what they JUST said and to this scenario — quote or react to their actual words/number. Good examples: "say the exact number — '15% more', not 'a bit more'", "don't accept 'let me check' — ask when they'll decide by", "drop the 'sorry' and just state what you want", "give one concrete result you delivered". NEVER use app or coaching jargon — do NOT use the words: hedge, assertive, passive, aggressive, register, cue, anchor, filler. Those are internal only. NO roasting, NO praise-only lines, NO questions. Vary it every turn — never repeat advice you already gave. Null only when the user is genuinely doing well and there's nothing useful to add.
- shouldEnd: true when the scene reaches a natural close OR after ~6-8 user turns.

TONE for callouts: a sharp communication coach. Concrete, direct, encouraging — never a roast, never therapist-speak.

Return JSON only — the schema is enforced.`;
}

function finalTurnAddendum() {
  return `⚠️ FINAL TURN — THIS IS THE LAST EXCHANGE.

The user has no more turns. Deliver a DEFINITIVE in-character OUTCOME.

Outcome rules — a win is the EXPECTED reward for solid (not perfect) play:
- Decide based on how the user actually performed across the whole conversation:
    • Reasonably clear, named a concrete ask, and held it without major folding → they get what they wanted. A solid run should win about half the time — don't demand perfection.
    • Hedged, apologized, stayed vague, lowered the ask, or talked themselves out of it throughout → they don't.
    • Borderline → partial win (e.g. "we can do 65 not 75, take it or leave it").
- State the outcome plainly.
- 1–2 sentences MAX. In character.
- ABSOLUTELY NO QUESTIONS. No "does that work?" No "what do you think?"
- NO open-ended deflection ("we'll see", "let me check") unless that itself IS the (bad) outcome.
- \`shouldEnd\` MUST be true.
- \`callout\` should be null OR a final summary observation, not a new criticism.`;
}

function verdictSystemPrompt(s) {
  return `You are the post-game commentator for "Don't Fold" — a Gen Z communication pressure-test app.

⚠️ CRITICAL — MEDIUM CONSTRAINT:
This is a voice + text conversation. You only have access to the WORDS the user
said/typed. You do NOT see the user. NEVER reference eye contact, body language,
posture, facial expressions, smiles, glances, gestures, head shakes, "tone of voice",
breathing, or anything physical. Every observation must come from the actual words
in the transcript — quote phrases when possible.

The user just attempted this scenario:
${s.title} — ${s.blurb}
Goal: ${s.userGoal}

Generate a recap card. Tone: Spotify Wrapped sass + internet humor.
Stylistically: bold, short, screenshottable, NOT corporate, NOT therapist-y, NOT mean.

⚠️ CRITICAL — TONE MUST MATCH PERFORMANCE.
The user's final confidence score tells you how they actually did.
Read it FIRST, then pick tone:

• Confidence ≥ 70 → CELEBRATE. Hype them. NO roasting. NO criticism.
• Confidence 40–69 → MIXED. Wry, balanced. Acknowledge what worked AND what wobbled.
• Confidence < 40 → ROAST (kindly). They folded. Lean into the sass.

HOW TO READ CONFIDENCE FROM THE TRANSCRIPT (you only have the words):
- HIGH = a concrete ask/number, specifics & examples, holding position under pushback, calm brevity, polite-AND-firm.
- LOW = hedges ("just", "maybe", "I think"), apologizing/permission-seeking/tag questions, vagueness, folding or lowering the ask, rambling.
- CRITICAL: confidence is ASSERTIVENESS, not AGGRESSION. Score a warm, respectful, firm performance as HIGH. Do NOT reward rudeness/bluntness or hostility, and do NOT penalize politeness or warmth.

JSON fields:
- finalConfidenceScore: integer 0–100 reflecting the user's overall composure
  across the WHOLE conversation. USE THE FULL RANGE — don't cluster around 50.
  This score MUST match the tier you're writing for. A roast verdict can't have a 75.
- verdictTitle: 2-4 word title in the right tier (e.g. "Main Character Energy",
  "Held The Line (Barely)", "Recovering People Pleaser").
- verdictVibe: ONE sentence (max 22 words) capturing the energy at that tier. Punchy.
- oneLinerToShare: ONE sentence under 80 chars, screenshottable. Match the tier.
- goodMoments: 1–3 specific things the user did well, drawn from the transcript.
  Concrete and single-line. For folds, still surface at least 1 moment that worked.
- improvementAreas: 1–3 specific things to do better next time, drawn from the transcript.
  Concrete and single-line. Direct, never mean.
- stats: 3-4 chips, each a REAL measurement counted from the transcript — never invented numbers.
  Count the same signals used during the conversation. Examples (compute the actual values):
    {label: "HEDGES", value: "3", detail: "just / maybe / I think"}   ← count hedging phrases the user actually used
    {label: "HELD THE LINE", value: "4/5", detail: null}              ← user turns where they held vs folded
    {label: "NUMBER NAMED", value: "Yes"} or {value: "No"}            ← did they ever state a concrete figure/ask
    {label: "REGISTER", value: "Assertive"}                            ← overall: Passive / Assertive / Aggressive
  Pick the 3-4 most telling for THIS run. Values must reflect what literally happened in the transcript.

Return JSON only.`;
}

function verdictUserPrompt(transcript, finalConfidence) {
  const convo = transcript
    .map((t) => `${t.speaker === "ai" ? "AI" : "USER"}: ${t.text}`)
    .join("\n");
  const c = Math.round(finalConfidence * 100);
  let tier;
  if (c >= 70) tier = "CELEBRATE — the user held strong. Hype them.";
  else if (c >= 40) tier = "MIXED — partial win. Wry, balanced tone.";
  else tier = "ROAST — they folded. Lean into the sass.";
  return `Final confidence: ${c}/100
→ Tier for this recap: ${tier}

Transcript:
${convo}`;
}

// ---- HTTP plumbing ---------------------------------------------------------

function contentsFromHistory(history) {
  // Gemini wants the trimmed sequence to start with a user message.
  let trimmed = history.slice(-16);
  while (trimmed.length > 1 && trimmed[0].speaker === "ai") trimmed.shift();
  return trimmed.map((t) => ({
    role: t.speaker === "ai" ? "model" : "user",
    parts: [{ text: t.text }],
  }));
}

// Retry rate-limits (429) and transient 5xx with exponential backoff before
// giving up — mirrors the iOS GeminiService. On final failure we throw so the
// UI can show an error + retry, instead of injecting fake canned lines.
const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);
const MAX_RETRIES = 2; // up to 3 attempts total
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function backoffDelay(attempt, retryAfterHeader) {
  const h = retryAfterHeader != null ? Number(retryAfterHeader) : NaN;
  if (isFinite(h) && h > 0) return Math.min(h * 1000, 8000); // honor Retry-After
  return 600 * Math.pow(2, attempt); // 600ms, 1200ms
}

async function callProxy(path, body) {
  let lastErr;
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    let resp;
    try {
      resp = await fetch(`${PROXY_BASE}${path}`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-App-Token": APP_TOKEN },
        body: JSON.stringify(body),
      });
    } catch (e) {
      lastErr = e; // network error — retry
      if (attempt === MAX_RETRIES) throw e;
      await sleep(backoffDelay(attempt));
      continue;
    }
    if (!resp.ok) {
      const text = await resp.text().catch(() => "");
      const err = new Error(`HTTP ${resp.status}: ${text.slice(0, 200)}`);
      err.status = resp.status;
      if (RETRYABLE_STATUSES.has(resp.status) && attempt < MAX_RETRIES) {
        lastErr = err;
        await sleep(backoffDelay(attempt, resp.headers.get("Retry-After")));
        continue;
      }
      throw err;
    }
    const data = await resp.json();
    const out = (data.candidates?.[0]?.content?.parts || [])
      .map((p) => p.text)
      .filter(Boolean)
      .join("");
    if (!out) throw new Error("Empty response from model");
    return out;
  }
  throw lastErr;
}

// Pull a JSON object out of whatever the model returned (fences, prose,
// truncation). Mirrors GeminiService.extractJSON.
export function extractJSON(raw) {
  let s = raw.trim();
  if (s.charCodeAt(0) === 0xfeff) s = s.slice(1);
  if (s.startsWith("```") || s.startsWith("~~~")) {
    const nl = s.indexOf("\n");
    if (nl !== -1) s = s.slice(nl + 1);
    if (s.endsWith("```")) s = s.slice(0, -3);
    if (s.endsWith("~~~")) s = s.slice(0, -3);
    s = s.trim();
  }
  const first = s.indexOf("{");
  if (first === -1) return s;
  s = s.slice(first);

  let depth = 0,
    inString = false,
    escape = false,
    end = -1;
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (escape) escape = false;
    else if (ch === "\\" && inString) escape = true;
    else if (ch === '"') inString = !inString;
    else if (!inString) {
      if (ch === "{") depth++;
      else if (ch === "}") {
        depth--;
        if (depth === 0) {
          end = i + 1;
          break;
        }
      }
    }
  }
  if (end !== -1) s = s.slice(0, end);
  else if (depth > 0) {
    if (inString) s += '"';
    s += "}".repeat(depth);
  }
  s = s.replace(/,\s*}/g, "}").replace(/,\s*]/g, "]");
  return s.trim();
}

// ---- Public API ------------------------------------------------------------

export async function nextTurn(scenario, history, isFinalTurn = false) {
  // First turn is the curated opening line (free, in-character).
  if (history.length === 0) {
    return {
      say: scenario.openingLine,
      confidenceDelta: 0,
      callout: null,
      shouldEnd: false,
    };
  }
  const systemPrompt = isFinalTurn
    ? `${turnSystemPrompt(scenario)}\n\n${finalTurnAddendum()}`
    : turnSystemPrompt(scenario);
  const body = {
    systemInstruction: { parts: [{ text: systemPrompt }] },
    contents: contentsFromHistory(history),
    generationConfig: {
      temperature: 0.92,
      topP: 0.9,
      maxOutputTokens: 700,
      responseMimeType: "application/json",
      responseSchema: TURN_SCHEMA,
    },
  };
  const raw = await callProxy("/turn", body);
  const obj = JSON.parse(extractJSON(raw));
  return {
    say: obj.say || "",
    confidenceDelta: toInt(obj.confidenceDelta, 0),
    callout: obj.callout || null,
    shouldEnd: !!obj.shouldEnd,
  };
}

export async function finalVerdict(scenario, transcript, finalConfidence) {
  const body = {
    systemInstruction: { parts: [{ text: verdictSystemPrompt(scenario) }] },
    contents: [
      {
        role: "user",
        parts: [{ text: verdictUserPrompt(transcript, finalConfidence) }],
      },
    ],
    generationConfig: {
      temperature: 0.9,
      topP: 0.9,
      maxOutputTokens: 2500,
      responseMimeType: "application/json",
      responseSchema: VERDICT_SCHEMA,
    },
  };
  try {
    const raw = await callProxy("/verdict", body);
    const o = JSON.parse(extractJSON(raw));
    return {
      verdictTitle: o.verdictTitle || "",
      verdictVibe: o.verdictVibe || "",
      oneLinerToShare: o.oneLinerToShare || "",
      finalConfidenceScore: toInt(o.finalConfidenceScore, 50),
      goodMoments: asStringArray(o.goodMoments),
      improvementAreas: asStringArray(o.improvementAreas),
      stats: (o.stats || []).map((s) => ({
        label: s.label || "",
        value: String(s.value ?? ""),
        detail: s.detail || null,
      })),
    };
  } catch (e) {
    return mockVerdict(transcript, finalConfidence);
  }
}

// OpenAI TTS via the proxy. Returns an object URL for an <audio> element, or
// null if TTS is unavailable (caller falls back to browser speechSynthesis).
export async function fetchTTS(text, voiceHint) {
  const voice = (voiceHint || "alloy").split(",")[0].trim() || "alloy";
  try {
    const resp = await fetch(`${PROXY_BASE}/tts`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-App-Token": APP_TOKEN },
      body: JSON.stringify({ voice, input: text }),
    });
    if (!resp.ok) return null;
    const blob = await resp.blob();
    return URL.createObjectURL(blob);
  } catch {
    return null;
  }
}

// Speech-to-text via the proxy (OpenAI Whisper). Takes a recorded audio Blob,
// returns the transcript string ("" on failure). Works in every browser that
// can record audio — unlike the built-in Web Speech API.
export async function transcribe(blob) {
  try {
    const resp = await fetch(`${PROXY_BASE}/stt`, {
      method: "POST",
      headers: {
        "Content-Type": blob.type || "audio/webm",
        "X-App-Token": APP_TOKEN,
      },
      body: blob,
    });
    if (!resp.ok) return "";
    const data = await resp.json();
    return (data.text || "").trim();
  } catch {
    return "";
  }
}

// Fire-and-forget usage beacon. event: "start" | "complete".
export function track(event, scenarioId) {
  try {
    fetch(`${PROXY_BASE}/track`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-App-Token": APP_TOKEN },
      body: JSON.stringify({ event, scenario: scenarioId }),
      keepalive: true, // still sends if the page is closing
    }).catch(() => {});
  } catch {
    /* never let tracking break the app */
  }
}

// ---- helpers / mock fallback ----------------------------------------------

function toInt(v, fallback) {
  if (typeof v === "number") return Math.round(v);
  if (typeof v === "string" && v.trim() !== "" && !isNaN(+v))
    return Math.round(+v);
  return fallback;
}
function asStringArray(v) {
  if (Array.isArray(v)) return v.map(String);
  if (typeof v === "string") return [v];
  return [];
}
function mockVerdict(transcript, finalConfidence) {
  const c = Math.round(finalConfidence * 100);
  const title =
    c >= 70 ? "Held The Room" : c >= 40 ? "Held The Line (Barely)" : "Folded On Impact";
  return {
    verdictTitle: title,
    verdictVibe:
      "Couldn't reach the recap model — showing a fallback. Try again to get the real read.",
    oneLinerToShare: "",
    finalConfidenceScore: c,
    goodMoments: ["Showed up and stayed in the conversation for every turn"],
    improvementAreas: ["Try again — the live model couldn't grade this round"],
    stats: [
      { label: "FINAL CONFIDENCE", value: String(c), detail: null },
      {
        label: "TURNS",
        value: String(transcript.filter((t) => t.speaker === "user").length),
        detail: null,
      },
    ],
  };
}
