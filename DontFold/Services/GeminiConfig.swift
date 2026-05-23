import Foundation

enum GeminiConfig {
    /// Look in this order:
    /// 1. `Info.plist` key `GEMINI_API_KEY`
    /// 2. Environment variable `GEMINI_API_KEY`
    /// 3. Local file at `~/Documents/dontfold_gemini_key.txt` (dev convenience)
    static var apiKey: String? {
        if let v = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !v.isEmpty, v != "$(GEMINI_API_KEY)" {
            return v
        }
        if let v = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !v.isEmpty {
            return v
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let url = docs?.appendingPathComponent("dontfold_gemini_key.txt"),
           let v = try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !v.isEmpty {
            return v
        }
        return nil
    }

    static var hasKey: Bool { apiKey != nil }

    /// Default model. Override if you want.
    static let model = "gemini-2.5-flash"

    static let endpointBase = "https://generativelanguage.googleapis.com/v1beta/models"
}
