import SwiftUI
import Observation

enum TurnSpeaker: String, Codable {
    case ai, user
}

struct Turn: Identifiable, Hashable, Codable {
    let id: UUID
    let speaker: TurnSpeaker
    let text: String
    let timestamp: Date
    var callout: String?

    init(speaker: TurnSpeaker, text: String, callout: String? = nil) {
        self.id = UUID()
        self.speaker = speaker
        self.text = text
        self.timestamp = Date()
        self.callout = callout
    }
}

enum ChallengePhase: Equatable {
    case intro
    case aiSpeaking
    case awaitingUser
    case userRecording
    case userTyping
    case sending
    case finished
}

@Observable
@MainActor
final class ChallengeSession {
    let id: UUID = UUID()
    let scenario: Scenario
    var phase: ChallengePhase = .intro
    var turns: [Turn] = []
    var confidence: Double = 0.55   // 0..1
    var lastCallout: String?
    var elapsedSeconds: Int = 0
    var maxTurns: Int = 6
    var errorMessage: String?

    /// Counts AI replies that aren't the hardcoded opening line. Used by the
    /// billing policy: aborting before this hits 2 doesn't deduct a credit.
    var aiReplyCount: Int = 0

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    var userTurnCount: Int {
        turns.filter { $0.speaker == .user }.count
    }

    var progress: Double {
        min(1.0, Double(userTurnCount) / Double(maxTurns))
    }

    func appendUser(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        turns.append(Turn(speaker: .user, text: trimmed))
    }

    func appendAI(_ text: String, callout: String?) {
        let isOpening = turns.isEmpty
        turns.append(Turn(speaker: .ai, text: text, callout: callout))
        if !isOpening { aiReplyCount += 1 }
        if let callout, !callout.isEmpty { lastCallout = callout }
    }

    func applyDelta(confidenceDelta: Int) {
        let c = confidence + Double(confidenceDelta) / 100.0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            confidence = max(0, min(1, c))
        }
    }
}
