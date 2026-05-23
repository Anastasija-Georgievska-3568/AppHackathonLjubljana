import Foundation

/// Lightweight on-device analysis. Augments the model's verdict with deterministic factoids.
enum TranscriptAnalyzer {
    private static let fillers = ["um", "uh", "like", "you know", "i mean", "kinda", "sorta", "basically", "literally", "actually"]
    private static let hedges = ["just", "maybe", "kind of", "sort of", "i guess", "i think", "probably", "if that's okay", "if it's not too much"]
    private static let apologies = ["sorry", "my bad", "apologies", "i apologize"]

    static func stats(from turns: [Turn]) -> [(label: String, value: String, detail: String?)] {
        let userText = turns.filter { $0.speaker == .user }.map { $0.text.lowercased() }.joined(separator: " ")
        let fillerCount = count(of: fillers, in: userText)
        let hedgeCount = count(of: hedges, in: userText)
        let apologyCount = count(of: apologies, in: userText)

        var stats: [(String, String, String?)] = []
        stats.append(("FILLERS", "\(fillerCount)", fillerCount > 5 ? "above average" : nil))
        stats.append(("HEDGES", "\(hedgeCount)", hedgeCount > 4 ? "soft" : nil))
        stats.append(("APOLOGIES", "\(apologyCount)", apologyCount > 2 ? "iconic" : nil))
        return stats
    }

    private static func count(of patterns: [String], in text: String) -> Int {
        patterns.reduce(0) { acc, pat in
            acc + text.components(separatedBy: pat).count - 1
        }
    }
}
