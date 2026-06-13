const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
const MODEL = "gemini-2.5-flash";
const OPENAI_TTS_URL = "https://api.openai.com/v1/audio/speech";
const TTS_MODEL = "tts-1-hd";

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Not found", { status: 404 });
    }

    const url = new URL(request.url);
    const path = url.pathname;
    if (path !== "/turn" && path !== "/verdict" && path !== "/tts") {
      return new Response("Not found", { status: 404 });
    }

    // Only our app (with the token) may use the proxy.
    const token = request.headers.get("X-App-Token");
    if (!token || token !== env.APP_TOKEN) {
      return new Response("Unauthorized", { status: 401 });
    }

    if (path === "/tts") {
      return handleTTS(request, env);
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

    return new Response(resp.body, {
      status: resp.status,
      headers: { "Content-Type": "application/json" },
    });
  },
};

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
