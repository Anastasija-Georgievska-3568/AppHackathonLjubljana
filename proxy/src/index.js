const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
const MODEL = "gemini-2.5-flash";
const OPENAI_TTS_URL = "https://api.openai.com/v1/audio/speech";
const TTS_MODEL = "tts-1-hd";
const OPENAI_STT_URL = "https://api.openai.com/v1/audio/transcriptions";
const STT_MODEL = "whisper-1";

// CORS. Origin is locked to env.ALLOWED_ORIGINS (comma-separated) when set;
// before that's configured it stays permissive so nothing breaks pre-launch.
const CORS_BASE = {
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-App-Token",
  "Access-Control-Max-Age": "86400",
};

function allowOrigin(request, env) {
  const origin = request.headers.get("Origin") || "";
  const list = (env.ALLOWED_ORIGINS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (list.length === 0) return "*"; // not configured yet — set ALLOWED_ORIGINS before launch
  if (origin && list.includes(origin)) return origin; // known origin: echo it
  return list[0]; // configured: never echo an unknown origin
}

function corsHeaders(request, env) {
  const h = new Headers(CORS_BASE);
  h.set("Access-Control-Allow-Origin", allowOrigin(request, env));
  h.set("Vary", "Origin");
  return h;
}

function withCors(resp, request, env) {
  const headers = new Headers(resp.headers);
  corsHeaders(request, env).forEach((v, k) => headers.set(k, v));
  return new Response(resp.body, { status: resp.status, headers });
}

// Coarse per-IP fixed-window rate limit (KV). Caps runaway abuse of the paid
// upstreams since the app token is necessarily public in a client-only app.
async function rateLimited(request, env) {
  if (!env.STATS) return false;
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const windowSec = 60;
  const limit = parseInt(env.RATE_LIMIT_PER_MIN || "40", 10) || 40;
  const bucket = Math.floor(Date.now() / 1000 / windowSec);
  const key = `rl:${ip}:${bucket}`;
  const count = parseInt((await env.STATS.get(key)) || "0", 10) || 0;
  if (count >= limit) return true;
  await env.STATS.put(key, String(count + 1), { expirationTtl: windowSec * 2 });
  return false;
}

export default {
  async fetch(request, env, ctx) {
    // Preflight: browsers send OPTIONS before a POST with custom headers.
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request, env) });
    }

    if (request.method !== "POST") {
      return withCors(new Response("Not found", { status: 404 }), request, env);
    }

    const url = new URL(request.url);
    const path = url.pathname;
    if (
      path !== "/turn" &&
      path !== "/verdict" &&
      path !== "/tts" &&
      path !== "/stt" &&
      path !== "/track" &&
      path !== "/feedback"
    ) {
      return withCors(new Response("Not found", { status: 404 }), request, env);
    }

    // Only our app (with the token) may use the proxy.
    const token = request.headers.get("X-App-Token");
    if (!token || token !== env.APP_TOKEN) {
      return withCors(new Response("Unauthorized", { status: 401 }), request, env);
    }

    // Throttle abuse of the paid endpoints.
    if (await rateLimited(request, env)) {
      return withCors(new Response("Rate limited", { status: 429 }), request, env);
    }

    if (path === "/track") {
      return withCors(await handleTrack(request, env, ctx), request, env);
    }

    if (path === "/tts") {
      return withCors(await handleTTS(request, env), request, env);
    }

    if (path === "/stt") {
      return withCors(await handleSTT(request, env), request, env);
    }

    if (path === "/feedback") {
      return withCors(await handleFeedback(request, env, ctx), request, env);
    }

    // Forward the body the app built straight to Gemini.
    const body = await request.text();
    const geminiURL =
      `${GEMINI_BASE}/${MODEL}:generateContent?key=${env.GEMINI_API_KEY}`;

    const resp = await fetch(geminiURL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    });

    return withCors(new Response(resp.body, {
      status: resp.status,
      headers: { "Content-Type": "application/json" },
    }), request, env);
  },
};

// Lightweight usage counters. The web client beacons {event, scenario} when a
// challenge starts ("start") and when a verdict is reached ("complete").
// Counts live in KV; read them with `wrangler kv key get`. Increments use a
// read-modify-write (good enough for demo scale — a rare race may undercount).
async function handleTrack(request, env, ctx) {
  if (!env.STATS) return new Response(null, { status: 204 });

  let payload = {};
  try {
    payload = await request.json();
  } catch {
    /* tolerate empty/bad body */
  }
  const event = ["start", "complete"].includes(payload.event)
    ? payload.event
    : "start";
  const scenario = String(payload.scenario || "unknown").slice(0, 40);
  const day = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  const keys = [
    `count:${event}:total`,
    `count:${event}:day:${day}`,
    `count:${event}:scenario:${scenario}`,
  ];

  const work = Promise.all(keys.map((k) => incr(env.STATS, k)));
  // Don't make the user wait on the write.
  if (ctx?.waitUntil) ctx.waitUntil(work);
  else await work;

  return new Response(null, { status: 204 });
}

// Beta feedback. The web client POSTs a small JSON survey. We append a row to a
// Google Sheet (via an Apps Script webhook in FEEDBACK_WEBHOOK_URL) AND keep a
// copy in KV as a safety net. If the webhook isn't configured yet, KV-only.
async function handleFeedback(request, env, ctx) {
  let p = {};
  try {
    p = await request.json();
  } catch {
    return new Response("Bad JSON", { status: 400 });
  }

  const clampRating = (v) => {
    const n = parseInt(v, 10);
    return Number.isFinite(n) ? Math.max(0, Math.min(5, n)) : 0;
  };
  const row = {
    ts: new Date().toISOString(),
    seniority: String(p.seniority || "").slice(0, 12),
    challenge: clampRating(p.challenge),
    challengeMore: String(p.challengeMore || "").slice(0, 2000),
    personasBelievable: clampRating(p.personasBelievable),
    personasUseful: clampRating(p.personasUseful),
    verdictAccuracy: clampRating(p.verdictAccuracy),
    repeatIntent: clampRating(p.repeatIntent),
    nextScenario: String(p.nextScenario || "").slice(0, 500),
    nativePref: String(p.nativePref || "").slice(0, 8),
    nativeLanguage: String(p.nativeLanguage || "").slice(0, 40),
    text: String(p.text || "").slice(0, 2000),
    email: String(p.email || "").slice(0, 200),
    deviceId: String(p.deviceId || "").slice(0, 64),
    scenario: String(p.scenario || "").slice(0, 40),
    persona: String(p.persona || "").slice(0, 60),
    score: String(p.score ?? "").slice(0, 8),
    band: String(p.band || "").slice(0, 20),
    userAgent: String(p.userAgent || "").slice(0, 300),
  };

  const work = [];
  if (env.FEEDBACK_WEBHOOK_URL) {
    work.push(
      fetch(env.FEEDBACK_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(row),
      }).catch(() => {})
    );
  }
  if (env.STATS) {
    work.push(env.STATS.put(`feedback:${row.ts}:${row.deviceId}`, JSON.stringify(row)));
    work.push(incr(env.STATS, "count:feedback:total"));
  }

  const all = Promise.all(work);
  if (ctx?.waitUntil) ctx.waitUntil(all);
  else await all;

  return new Response(null, { status: 204 });
}

async function incr(kv, key) {
  const current = parseInt((await kv.get(key)) || "0", 10) || 0;
  await kv.put(key, String(current + 1));
}

async function handleTTS(request, env) {
  if (!env.OPENAI_API_KEY) {
    return new Response("TTS not configured", { status: 503 });
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return new Response("Bad JSON", { status: 400 });
  }

  const voice = typeof payload.voice === "string" ? payload.voice : "alloy";
  const input = typeof payload.input === "string" ? payload.input : "";
  if (!input.trim()) {
    return new Response("Empty input", { status: 400 });
  }

  const resp = await fetch(OPENAI_TTS_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: TTS_MODEL,
      voice,
      input,
      response_format: "mp3",
    }),
  });

  if (!resp.ok) {
    const text = await resp.text();
    return new Response(text, { status: resp.status });
  }

  return new Response(resp.body, {
    status: 200,
    headers: { "Content-Type": "audio/mpeg" },
  });
}

// Speech-to-text via OpenAI Whisper. The web client records mic audio with
// MediaRecorder and POSTs the raw blob here (works in every modern browser,
// unlike the built-in Web Speech API). Returns { text }.
async function handleSTT(request, env) {
  if (!env.OPENAI_API_KEY) {
    return new Response("STT not configured", { status: 503 });
  }

  const contentType = request.headers.get("Content-Type") || "audio/webm";
  const buf = await request.arrayBuffer();
  if (!buf || buf.byteLength === 0) {
    return new Response("Empty audio", { status: 400 });
  }

  const ext = contentType.includes("mp4")
    ? "mp4"
    : contentType.includes("ogg")
    ? "ogg"
    : contentType.includes("wav")
    ? "wav"
    : "webm";

  const form = new FormData();
  form.append("file", new Blob([buf], { type: contentType }), `audio.${ext}`);
  form.append("model", STT_MODEL);
  form.append("language", "en"); // app is English-only; stops Whisper guessing other languages
  form.append("response_format", "json");

  const resp = await fetch(OPENAI_STT_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${env.OPENAI_API_KEY}` },
    body: form,
  });

  if (!resp.ok) {
    const text = await resp.text();
    return new Response(text, { status: resp.status });
  }

  const data = await resp.json();
  return new Response(JSON.stringify({ text: data.text || "" }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}
