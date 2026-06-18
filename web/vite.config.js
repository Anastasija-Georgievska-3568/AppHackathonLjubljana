import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// In dev we proxy /proxy/* -> the deployed Cloudflare Worker so the browser
// never makes a cross-origin request (no CORS dance while developing).
// In a production build the app calls the Worker directly (the Worker now
// sends CORS headers).
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/proxy": {
        target: "https://dontfold-proxy.dontfold.workers.dev",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/proxy/, ""),
      },
    },
  },
});
