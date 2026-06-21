// Don't Fold — raise-negotiation engine.
// Two internal personas, two calls per user turn (run in parallel by the caller):
//   CHARACTER — the manager, pure in-character roleplay (no scoring, no coaching).
//   COACH     — the evaluator, scores the turn 0–100 and writes one coaching note.
// A separate COACH debrief runs at the end. See the Agent Guidelines doc.

const PROXY_BASE = import.meta.env.DEV
  ? "/proxy" // vite proxies to the worker (no CORS in dev)
  : "https://dontfold-proxy.dontfold.workers.dev";

const APP_TOKEN =
  import.meta.env.VITE_APP_TOKEN ||
  "1e5ba1cb1fea44ab80d52b05984206fd8d8d86db42ea24b0208415b6732337df";

// ---- Schemas (Gemini structured output) -----------------------------------

const CHARACTER_SCHEMA = {
  type: "OBJECT",
  properties: {
    say: { type: "STRING" },
    shouldEnd: { type: "BOOLEAN" },
  },
  required: ["say", "shouldEnd"],
};

const COACH_SCHEMA = {
  type: "OBJECT",
  properties: {
    note: { type: "STRING" },
    score: { type: "INTEGER" },
  },
  required: ["note", "score"],
};

const DEBRIEF_SCHEMA = {
  type: "OBJECT",
  properties: {
    finalScore: { type: "INTEGER" },
    band: { type: "STRING" },
    verdictTitle: { type: "STRING" },
    oneLinerToShare: { type: "STRING" },
    heldBest: { type: "STRING" },
    biggestLeakQuote: { type: "STRING" },
    biggestLeakBetter: { type: "STRING" },
    practice: { type: "STRING" },
  },
  required: [
    "finalScore",
    "band",
    "verdictTitle",
    "heldBest",
    "biggestLeakBetter",
    "practice",
  ],
};

// ---- CHARACTER (the manager) ----------------------------------------------

function characterSystemPrompt(s) {
  return `You are role-playing ONE character — a manager — in "Don't Fold", a voice app where the user practices asking their current manager for a raise. You are NOT a coach. You never give advice, never break character, never grade the user. You only speak as the manager.

WHO YOU ARE:
${s.aiPersona}

THE SCENE: ${s.setup}
The user (your report) has booked this meeting. Their goal: ${s.userGoal}

HOW THE APP WORKS — READ CAREFULLY:
- It's turn-based. You only speak after the user finishes. You are NOT under time pressure and the user is NOT leaving you in silence — so NEVER use, mention, or react to "silence", "pauses", or "letting it sit". That tactic does not exist here. Difficulty comes from your words and your standards, not from waiting.

HOW YOU BEHAVE:
- Always push back at least once with a real, in-character objection before conceding anything — even a strong, well-framed ask earns pushback first.
- React to how the user actually performs. If they're vague, pleading, emotional, or fold, get less committal in your own style. If they're calm, specific, frame their value, and connect with you, engage seriously and move toward REAL movement — "let me see what I can do", a counter, a partial, a path with a date. Never a clean instant "yes".
- Pressure, never abuse. You can be dismissive, slippery, vague, cold, or overly sweet — but never demeaning, discriminatory, or cruel. The goal is nerve, not harm.
- Stay human: never repeat a sentence or point you already made (read your previous lines); each turn adds something new or shifts. When the user pushes the same point 2–3 times, move — give ground, change angle, or back off. Real people don't restate the identical position forever.

VOICE:
- 1–2 sentences, 3 max. Spoken, natural, contractions. No lists. Lead with a reaction, not "I".
- React to the specific words the user just used.

Return JSON only: { say, shouldEnd }. Set shouldEnd true only when the scene reaches a natural close (a decision, a concrete next step, or a clear dead end).`;
}

// ---- COACH (the evaluator) -------------------------------------------------

function coachSystemPrompt(s) {
  return `You are the COACH in "Don't Fold" — a sharp, warm negotiation coach evaluating a user practicing asking their manager for a raise. You are NOT the manager. You judge the USER's most recent message and give ONE short coaching note. Honest, specific, never a therapy voice.

THE MANAGER THEY'RE FACING (tailor your advice to beating THIS person):
${s.aiPersona}
This manager most tests: ${s.keySkills}. Weight those two skills hardest.

WHAT GREAT LOOKS LIKE (the skills you score):
- Composure: holds the position when pushed; doesn't cave, apologize it away, or ramble.
- Reading & connecting: listens, reflects the manager's position back, asks open "how/what" questions, builds a little warmth, adapts to this persona.
- Evidence over emotion: grounds the ask in contribution/impact, said calmly — NOT feelings, need ("rent", "cost of living"), unfairness, or tenure alone.
- Clear, confident words: plain, direct sentences; free of weak words (just, only, maybe, I think, I feel, sort of, hopefully) and of asking permission to even bring it up.
- Assertive tone: firm AND warm. Owns the request as reasonable. Not pleading, not aggressive.
- Order of the ask: frames value BEFORE any number; never leads with the figure; if a number comes, starts high.
- Productive close: ends with a concrete next step — a number, a date, an owner.

SCORE (0–100, the WHOLE conversation so far, not just this line). Weighting: Composure 20, Reading & connecting 20, Evidence 15, Clear words 15, Assertive tone 15, Order of ask 10, Close 5. Bands: 0–39 Folded, 40–59 Shaky, 60–79 Steady, 80–100 Strong.
- Biggest score drag: the user lowers their own number or softens their position to ease their OWN discomfort, getting nothing back — penalize hard (Composure).
- Leading with a bare number, or fixating on the figure, is penalized (Order of ask, drags Evidence) — a number with no framing is just a demand.
- Strong framing followed by an instant cave is Shaky, not Steady. Score the arc.
- Do NOT verify their data. Judge whether the reasoning SOUNDS calm/evidence-based vs emotional/need-driven.

THE NOTE (one short coaching line, 1–2 sentences, shown on screen next to the manager's reply):
- ONE point only. Praise one specific thing they did, OR give one better move, OR a quick mix of one praise + one tweak. NEVER stack two criticisms.
- Plain spoken English, like a friend coaching mid-conversation. NEVER use jargon (composure, assertive, register, cue, hedge, filler, etc.).
- If they slipped, name it gently and hand them the fix WITH a short sample line that works against THIS manager.
- If they did well, praise the specific move so they repeat it. If they fixed an earlier miss, call out the progress.
- Match their state: if they sound nervous, encourage and keep the fix small; if they're strong, push harder.
- Point forward (what to try next turn). Never repeat the previous note — change the angle if they keep missing the same thing.

Return JSON only: { note, score }.`;
}

function coachUserPrompt(history, lastNote) {
  const convo = history
    .map((t) => `${t.speaker === "ai" ? "MANAGER" : "USER"}: ${t.text}`)
    .join("\n");
  const lastUser = [...history].reverse().find((t) => t.speaker === "user");
  const prev = lastNote
    ? `\nYour previous note (do NOT repeat it — change the angle): "${lastNote}"`
    : "";
  return `Conversation so far:
${convo}

Evaluate the USER's most recent message: "${lastUser ? lastUser.text : ""}"
Score the whole run so far (0–100) and write ONE coaching note for their next move.${prev}`;
}

// ---- COACH debrief (end of run) -------------------------------------------

function debriefSystemPrompt() {
  return `You are the COACH giving the end-of-run debrief for "Don't Fold" (asking a manager for a raise). Warm, direct, specific, honest — a folded negotiation gets called a fold, kindly. Never a therapy voice. You only have the WORDS in the transcript — never reference tone of voice, body language, or silence.

Score the WHOLE conversation 0–100 using this weighting: Composure 20, Reading & connecting 20, Evidence over emotion 15, Clear confident words 15, Assertive tone 15, Order of the ask 10, Productive close 5. Bands: 0–39 Folded, 40–59 Shaky, 60–79 Steady, 80–100 Strong.
Penalize hard: caving / lowering their own number to ease discomfort, leading with a bare number, arguing from emotion or personal need. Reward: framing value before any number, reading and connecting with the manager, calm evidence, holding under pushback, pinning a concrete commitment, a clean close.

Return JSON only:
- finalScore: 0–100, matching the band.
- band: "Folded" | "Shaky" | "Steady" | "Strong".
- verdictTitle: 2–4 words in the right tier.
- oneLinerToShare: <80 chars, screenshottable, matches the tier.
- heldBest: ONE sentence on what held best across the run.
- biggestLeakQuote: the user's actual words at their single biggest leak (quote from the transcript; "" if they were strong throughout).
- biggestLeakBetter: a better version of that line.
- practice: ONE concrete thing to practice next run.`;
}

function debriefUserPrompt(transcript, finalScore) {
  const convo = transcript
    .map((t) => `${t.speaker === "ai" ? "MANAGER" : "USER"}: ${t.text}`)
    .join("\n");
  return `Running score at the end: ${Math.round(finalScore)}/100.

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

// Pull a JSON object out of whatever the model returned (fences, prose, truncation).
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

// CHARACTER: the manager's in-character reply. No scoring, no coaching.
export async function nextTurn(scenario, history, isFinalTurn = false) {
  // First turn is the curated opening line (free, in-character).
  if (history.length === 0) {
    return { say: scenario.openingLine, shouldEnd: false };
  }
  const systemPrompt = isFinalTurn
    ? `${characterSystemPrompt(scenario)}\n\nFINAL TURN — deliver a definitive in-character outcome (a decision, a concrete partial, or a clear dead end). 1–2 sentences. No questions. shouldEnd MUST be true.`
    : characterSystemPrompt(scenario);
  const body = {
    systemInstruction: { parts: [{ text: systemPrompt }] },
    contents: contentsFromHistory(history),
    generationConfig: {
      temperature: 0.92,
      topP: 0.9,
      maxOutputTokens: 400,
      responseMimeType: "application/json",
      responseSchema: CHARACTER_SCHEMA,
    },
  };
  const raw = await callProxy("/turn", body);
  const obj = JSON.parse(extractJSON(raw));
  return { say: obj.say || "", shouldEnd: !!obj.shouldEnd };
}

// COACH: evaluate the user's latest message → { note, score }. Returns null on
// failure so a coaching hiccup never blocks the manager's reply.
export async function coachTurn(scenario, history, lastNote = "") {
  const body = {
    systemInstruction: { parts: [{ text: coachSystemPrompt(scenario) }] },
    contents: [{ role: "user", parts: [{ text: coachUserPrompt(history, lastNote) }] }],
    generationConfig: {
      temperature: 0.4,
      topP: 0.9,
      maxOutputTokens: 400,
      responseMimeType: "application/json",
      responseSchema: COACH_SCHEMA,
    },
  };
  try {
    const raw = await callProxy("/turn", body);
    const o = JSON.parse(extractJSON(raw));
    const score = clampScore(toInt(o.score, 50));
    const note = (o.note || "").trim();
    return { note: note || null, score };
  } catch {
    return null;
  }
}

// COACH debrief at the end of the run.
export async function finalVerdict(scenario, transcript, finalScore) {
  const body = {
    systemInstruction: { parts: [{ text: debriefSystemPrompt() }] },
    contents: [
      { role: "user", parts: [{ text: debriefUserPrompt(transcript, finalScore) }] },
    ],
    generationConfig: {
      temperature: 0.7,
      topP: 0.9,
      maxOutputTokens: 1200,
      responseMimeType: "application/json",
      responseSchema: DEBRIEF_SCHEMA,
    },
  };
  try {
    const raw = await callProxy("/verdict", body);
    const o = JSON.parse(extractJSON(raw));
    const score = clampScore(toInt(o.finalScore, Math.round(finalScore)));
    return {
      finalScore: score,
      band: o.band || bandFor(score),
      verdictTitle: o.verdictTitle || bandFor(score),
      oneLinerToShare: o.oneLinerToShare || "",
      heldBest: o.heldBest || "",
      biggestLeakQuote: o.biggestLeakQuote || "",
      biggestLeakBetter: o.biggestLeakBetter || "",
      practice: o.practice || "",
    };
  } catch {
    return mockVerdict(transcript, finalScore);
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
// returns the transcript string ("" on failure).
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
      keepalive: true,
    }).catch(() => {});
  } catch {
    /* never let tracking break the app */
  }
}

// ---- helpers ---------------------------------------------------------------

function toInt(v, fallback) {
  if (typeof v === "number") return Math.round(v);
  if (typeof v === "string" && v.trim() !== "" && !isNaN(+v)) return Math.round(+v);
  return fallback;
}
function clampScore(n) {
  return Math.max(0, Math.min(100, n));
}
export function bandFor(score) {
  if (score >= 80) return "Strong";
  if (score >= 60) return "Steady";
  if (score >= 40) return "Shaky";
  return "Folded";
}

function mockVerdict(transcript, finalScore) {
  const score = clampScore(Math.round(finalScore));
  return {
    finalScore: score,
    band: bandFor(score),
    verdictTitle: bandFor(score),
    oneLinerToShare: "",
    heldBest: "You showed up and stayed in the conversation every turn.",
    biggestLeakQuote: "",
    biggestLeakBetter: "Couldn't reach the recap model — run it back for the real read.",
    practice: "Lead with one concrete result before any number.",
  };
}
