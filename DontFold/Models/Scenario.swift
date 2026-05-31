import SwiftUI

enum Difficulty: String, Codable, Hashable, CaseIterable {
    case mild, spicy, brutal

    var label: String {
        switch self {
        case .mild: "Mild"
        case .spicy: "Spicy"
        case .brutal: "Brutal"
        }
    }

    var level: Int {
        switch self {
        case .mild: 1
        case .spicy: 2
        case .brutal: 3
        }
    }

    var tint: Color {
        switch self {
        case .mild: Theme.ink
        case .spicy: Theme.accent
        case .brutal: Theme.accent
        }
    }
}

enum ScenarioCategory: String, Codable, Hashable, CaseIterable {
    case career, money, life, phone, social, food

    var label: String {
        switch self {
        case .career: "Career"
        case .money: "Money"
        case .life: "Life Admin"
        case .phone: "Phone Calls"
        case .social: "Social"
        case .food: "Food & Service"
        }
    }

    var systemImage: String {
        switch self {
        case .career: "briefcase.fill"
        case .money: "dollarsign.circle.fill"
        case .life: "house.fill"
        case .phone: "phone.fill"
        case .social: "person.2.fill"
        case .food: "fork.knife"
        }
    }

    /// In Hot Girl CEO every category reads in hot pink — we lean on the
    /// title, not the badge, to differentiate.
    var tint: Color {
        Theme.accent
    }
}

struct Scenario: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let blurb: String              // one-liner for cards
    let setup: String              // longer scene description (Brief screen)
    let category: ScenarioCategory
    let difficulty: Difficulty
    let aiPersona: String          // e.g. "Hiring manager, slightly impatient"
    let aiVoiceHint: String        // gender/age hint for TTS
    let openingLine: String        // AI's first spoken line
    let userGoal: String           // what the user is trying to accomplish
    let pressureCues: [String]     // "avoid this" list — phrases / moves
    let confidenceCues: [String]   // things that read as holding the line
}
