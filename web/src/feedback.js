// Beta feedback funnel — anonymous, no login.
// Posts a short survey to the worker (which forwards to a Google Sheet) and uses
// localStorage to identify the device and to never re-prompt after submit/dismiss.

const PROXY_BASE = import.meta.env.DEV
  ? "/proxy"
  : "https://dontfold-proxy.dontfold.workers.dev";

const APP_TOKEN =
  import.meta.env.VITE_APP_TOKEN ||
  "1e5ba1cb1fea44ab80d52b05984206fd8d8d86db42ea24b0208415b6732337df";

const K_DEVICE = "df_device_id";
const K_RUNS = "df_runs_completed";
const K_PROMPTED = "df_feedback_prompted"; // auto-prompt has been shown once
const K_DONE = "df_feedback_done"; // user submitted feedback

function ls() {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

export function getDeviceId() {
  const store = ls();
  if (!store) return "no-storage";
  let id = store.getItem(K_DEVICE);
  if (!id) {
    id =
      (crypto?.randomUUID && crypto.randomUUID()) ||
      `dev-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    store.setItem(K_DEVICE, id);
  }
  return id;
}

// Count a finished run; returns the new total.
export function markCompletedRun() {
  const store = ls();
  if (!store) return 0;
  const n = (parseInt(store.getItem(K_RUNS) || "0", 10) || 0) + 1;
  store.setItem(K_RUNS, String(n));
  return n;
}

export function feedbackPrompted() {
  return ls()?.getItem(K_PROMPTED) === "1";
}
export function markPrompted() {
  ls()?.setItem(K_PROMPTED, "1");
}
export function feedbackDone() {
  return ls()?.getItem(K_DONE) === "1";
}
export function markDone() {
  ls()?.setItem(K_DONE, "1");
}

// True when we should auto-open the prompt: first completed run, not already
// prompted, not already submitted.
export function shouldAutoPrompt(runCount) {
  return runCount >= 1 && !feedbackPrompted() && !feedbackDone();
}

export async function submitFeedback(payload) {
  const body = {
    ...payload,
    deviceId: getDeviceId(),
    userAgent: typeof navigator !== "undefined" ? navigator.userAgent : "",
  };
  try {
    const resp = await fetch(`${PROXY_BASE}/feedback`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-App-Token": APP_TOKEN },
      body: JSON.stringify(body),
      keepalive: true,
    });
    return resp.ok;
  } catch {
    return false;
  }
}
