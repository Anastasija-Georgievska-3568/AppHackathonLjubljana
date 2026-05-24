import Foundation

/// Reads a `.env` file bundled with the app at build time.
///
/// Format: one `KEY=VALUE` per line. Lines starting with `#` are ignored.
/// Values may optionally be wrapped in single or double quotes.
enum DotEnv {
    private static let values: [String: String] = load()

    static subscript(key: String) -> String? {
        let v = values[key]
        return (v?.isEmpty ?? true) ? nil : v
    }

    private static func load() -> [String: String] {
        // `Bundle.url(forResource:withExtension:)` is unreliable for dotfiles like
        // `.env` because Foundation parses everything after the dot as the extension.
        // Fall back to a direct bundle path.
        let direct = Bundle.main.bundleURL.appendingPathComponent(".env")
        let viaAPI = Bundle.main.url(forResource: ".env", withExtension: nil)
            ?? Bundle.main.url(forResource: "", withExtension: "env")
        let candidates: [URL] = [direct, viaAPI].compactMap { $0 }
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var dict: [String: String] = [:]
        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            dict[key] = value
        }
        return dict
    }
}
