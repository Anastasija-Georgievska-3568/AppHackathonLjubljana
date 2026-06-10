import Foundation

enum GeminiConfig {
    /// Cloudflare Worker proxy. The real Gemini key lives on the Worker, never here.
    static let proxyBase = "https://dontfold-proxy.dontfold.workers.dev"
    
    /// Shared token so only this app can use the proxy. Not a Gemini key —
    /// rotate via `wrangler secret put APP_TOKEN` if it leaks.
    static let appToken = "1e5ba1cb1fea44ab80d52b05984206fd8d8d86db42ea24b0208415b6732337df"
    
    /// True once the proxy is configured (placeholder not left in).
    static var hasKey: Bool {
        !proxyBase.isEmpty && !appToken.isEmpty
    }
}
