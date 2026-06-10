const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
  const MODEL = "gemini-2.5-flash";

  export default {
    async fetch(request, env) {
      if (request.method !== "POST") {
        return new Response("Not found", { status: 404 });
      }

      const url = new URL(request.url);
      if (url.pathname !== "/turn" && url.pathname !== "/verdict") {
        return new Response("Not found", { status: 404 });
      }

      // Only our app (with the token) may use the proxy.
      const token = request.headers.get("X-App-Token");
      if (!token || token !== env.APP_TOKEN) {
        return new Response("Unauthorized", { status: 401 });
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

