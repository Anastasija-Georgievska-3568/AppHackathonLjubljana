import SwiftUI

struct SessionResult: Hashable, Codable {
    let id: UUID
    let scenarioTitle: String
    let scenarioId: String
    let verdictTitle: String       // e.g. "Recovering People Pleaser"
    let verdictVibe: String        // 1-2 sentence summary in roast-y Gen Z tone
    let oneLinerToShare: String    // pithy, for the share card
    let highlights: [String]       // 2-4 quick observations
    let stats: [ResultStat]
    let finalConfidence: Double
    let date: Date
    let transcript: [Turn]

    init(
        scenarioTitle: String,
        scenarioId: String,
        verdictTitle: String,
        verdictVibe: String,
        oneLinerToShare: String,
        highlights: [String],
        stats: [ResultStat],
        finalConfidence: Double,
        transcript: [Turn]
    ) {
        self.id = UUID()
        self.scenarioTitle = scenarioTitle
        self.scenarioId = scenarioId
        self.verdictTitle = verdictTitle
        self.verdictVibe = verdictVibe
        self.oneLinerToShare = oneLinerToShare
        self.highlights = highlights
        self.stats = stats
        self.finalConfidence = finalConfidence
        self.date = Date()
        self.transcript = transcript
    }
}

struct ResultStat: Hashable, Codable {
    let label: String
    let value: String
    let detail: String?
}

enum VerdictTemplates {
    static let fold = [
        "Recovering People Pleaser",
        "Professional Overexplainer",
        "Folded On Impact",
        "Apology First, Sentence Later",
        "Emotional Surrender, Mild Pressure Edition",
    ]
    static let mid = [
        "Held The Line (Barely)",
        "Mostly Composed",
        "Polite Until Pressured",
        "Negotiated With Yourself",
    ]
    static let hold = [
        "Main Character Energy",
        "Unbothered",
        "Quietly Devastating",
        "Held The Room",
    ]

    static func fallback(confidence: Double) -> String {
        if confidence < 0.35 { return fold.randomElement()! }
        if confidence < 0.7 { return mid.randomElement()! }
        return hold.randomElement()!
    }
}
