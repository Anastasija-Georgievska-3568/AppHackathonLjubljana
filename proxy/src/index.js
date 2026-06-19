const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
const MODEL = "gemini-2.5-flash";
const OPENAI_TTS_URL = "https://api.openai.com/v1/audio/speech";
const TTS_MODEL = "tts-1-hd";
const OPENAI_STT_URL = "https://api.openai.com/v1/audio/transcriptions";
const STT_MODEL = "whisper-1";

// CORS so the web client (different origin) can call the proxy from a browser.
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-App-Token",
  "Access-Control-Max-Age": "86400",
};

function withCors(resp) {
  const headers = new Headers(resp.headers);
  for (const [k, v] of Object.entries(CORS_HEADERS)) headers.set(k, v);
  return new Response(resp.body, { status: resp.status, headers });
}

export default {
  async fetch(request, env, ctx) {
    // Preflight: browsers send OPTIONS before a POST with custom headers.
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== "POST") {
      return withCors(new Response("Not found", { status: 404 }));
    }

    const url = new URL(request.url);
    const path = url.pathname;
    if (
      path !== "/turn" &&
      path !== "/verdict" &&
      path !== "/tts" &&
      path !== "/stt" &&
      path !== "/track"
    ) {
      return withCors(new Response("Not found", { status: 404 }));
    }

    // Only our app (with the token) may use the proxy.
    const token = request.headers.get("X-App-Token");
    if (!token || token !== env.APP_TOKEN) {
      return withCors(new Response("Unauthorized", { status: 401 }));
    }

    if (path === "/track") {
      return withCors(await handleTrack(request, env, ctx));
    }

    if (path === "/tts") {
      return withCors(await handleTTS(request, env));
    }

    if (path === "/stt") {
      return withCors(await handleSTT(request, env));
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
    }));
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
