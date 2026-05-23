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
        case .mild: Theme.accent3
        case .spicy: Theme.warning
        case .brutal: Theme.danger
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

    var tint: Color {
        switch self {
        case .career: Theme.accent2
        case .money: Theme.warning
        case .life: Theme.accent3
        case .phone: Theme.accent
        case .social: Color(hex: 0xFF7AE0)
        case .food: Color(hex: 0xFFB266)
        }
    }
}

struct Scenario: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let blurb: String              // a one-liner for cards
    let setup: String              // longer scene-setting text shown on detail
    let category: ScenarioCategory
    let difficulty: Difficulty
    let aiPersona: String          // e.g. "Hiring manager, slightly impatient"
    let aiVoiceHint: String        // gender/age hint for TTS
    let openingLine: String        // AI's first spoken line
    let userGoal: String           // what the user is trying to accomplish
    let pressureCues: [String]     // things that should crank pressure ("vague answer", "overexplaining")
    let confidenceCues: [String]   // things that should boost confidence ("clear ask", "named a number")
}
