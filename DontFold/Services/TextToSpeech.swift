import Foundation
import AVFoundation

@MainActor
final class TextToSpeech: NSObject {
    static let shared = TextToSpeech()

    private let synth = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, voiceHint: String? = nil) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true, options: [])
            } catch { /* non-fatal */ }

            let profile = VoiceProfile.from(hint: voiceHint)
            let utter = AVSpeechUtterance(string: humanize(text))
            utter.rate = profile.rate
            utter.pitchMultiplier = profile.pitch
            utter.volume = 1.0
            utter.preUtteranceDelay = 0.08
            utter.postUtteranceDelay = 0.05
            utter.voice = Self.pickVoice(for: profile)
            #if DEBUG
            let allEnglish = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
            let premium = allEnglish.filter { $0.quality == .premium }
            let enhanced = allEnglish.filter { $0.quality == .enhanced }
            let defaults = allEnglish.filter { $0.quality == .default }
            print("[TTS] hint=\(voiceHint ?? "nil") → using:", utter.voice?.name ?? "?",
                  "lang:", utter.voice?.language ?? "?",
                  "quality:", utter.voice?.quality.rawValue ?? -1,
                  "(3=Premium, 2=Enhanced, 1=Default)")
            print("[TTS] PREMIUM English voices:", premium.isEmpty ? "NONE" : premium.map { "\($0.name) [\($0.language)]" }.joined(separator: ", "))
            print("[TTS] ENHANCED English voices:", enhanced.isEmpty ? "NONE" : enhanced.map { "\($0.name) [\($0.language)]" }.joined(separator: ", "))
            print("[TTS] DEFAULT English voices:", defaults.map { "\($0.name) [\($0.language)]" }.joined(separator: ", "))
            #endif
            synth.speak(utter)
        }
    }

    func stop() {
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        continuation?.resume()
        continuation = nil
    }

    /// Insert subtle pauses so the synthesizer breathes instead of rattling.
    /// AVSpeech respects commas/ellipses for prosody — we lean into that.
    private func humanize(_ text: String) -> String {
        var out = text
        // Add a soft pause after sentence-ending punctuation if the synth is rushing it.
        out = out.replacingOccurrences(of: ".", with: ". ")
        out = out.replacingOccurrences(of: "?", with: "? ")
        out = out.replacingOccurrences(of: "!", with: "! ")
        // Collapse accidental double-spaces.
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// Pick the best available voice for the requested profile.
    ///
    /// Order of preference:
    /// 1. A voice matching the profile's preferred identifier substring AND `.premium` quality
    /// 2. Same identifier, `.enhanced` quality
    /// 3. Any English voice with `.premium` quality (any gender)
    /// 4. Any English voice with `.enhanced` quality
    /// 5. Same identifier, `.default` quality
    /// 6. The system default for the language
    private static func pickVoice(for profile: VoiceProfile) -> AVSpeechSynthesisVoice? {
        let allEnglish = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }

        let preferredIDs = profile.preferredIdentifierSubstrings

        // Helper that picks the first voice whose identifier contains one of the substrings.
        func first(in voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
            for sub in preferredIDs {
                if let v = voices.first(where: { $0.identifier.lowercased().contains(sub) }) {
                    return v
                }
            }
            return nil
        }

        let premium = allEnglish.filter { $0.quality == .premium }
        if let v = first(in: premium) { return v }

        let enhanced = allEnglish.filter { $0.quality == .enhanced }
        if let v = first(in: enhanced) { return v }

        if let any = premium.first { return any }
        if let any = enhanced.first { return any }

        if let v = first(in: allEnglish) { return v }

        return AVSpeechSynthesisVoice(language: profile.preferredLanguage)
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}

extension TextToSpeech: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}

// MARK: - Voice profile

/// A bundle of TTS parameters tuned for each persona archetype.
struct VoiceProfile {
    var rate: Float
    var pitch: Float
    var preferredLanguage: String
    var preferredIdentifierSubstrings: [String]

    /// Substring lists are ordered: preferred voice first, then graceful fallbacks.
    /// On a real iPhone with Premium voices downloaded, the first match wins.
    /// On Simulator, falls through to lower-tier Default voices.
    static let `default` = VoiceProfile(
        rate: 0.47,
        pitch: 1.0,
        preferredLanguage: "en-US",
        preferredIdentifierSubstrings: ["matilda", "samantha"]
    )

    static func from(hint: String?) -> VoiceProfile {
        let hint = (hint ?? "").lowercased()

        // Interviewer / hiring manager — male, serious, professional.
        // Checked BEFORE the warm bucket so "warm, lightly impatient" still routes here.
        // → Jamie (Premium GB male), deliberate and authoritative.
        if hint.contains("interview") || hint.contains("hiring") || hint.contains("impatient") {
            return VoiceProfile(
                rate: 0.46,
                pitch: 0.91,
                preferredLanguage: "en-GB",
                preferredIdentifierSubstrings: ["jamie", "lee", "daniel", "evan"]
            )
        }

        // Warm / friendly (server, friend)
        // → Matilda (Premium AU female, naturally warm)
        if hint.contains("warm") || hint.contains("friendly") || hint.contains("upbeat") || hint.contains("playful") {
            return VoiceProfile(
                rate: 0.49,
                pitch: 1.08,
                preferredLanguage: "en-AU",
                preferredIdentifierSubstrings: ["matilda", "ava", "allison", "samantha"]
            )
        }

        // Fast / clipped (receptionist, scripted bank agent)
        // → Serena (Premium GB female, naturally polished/clipped)
        if hint.contains("fast") || hint.contains("clipped") || hint.contains("scripted") || hint.contains("professional") {
            return VoiceProfile(
                rate: 0.55,
                pitch: 1.00,
                preferredLanguage: "en-GB",
                preferredIdentifierSubstrings: ["serena", "jamie", "karen", "kate"]
            )
        }

        // Calm / measured / evasive (manager negotiating, quitting boss)
        // → Jamie (Premium GB male, lower, measured) — slow and dropped pitch
        if hint.contains("calm") || hint.contains("measured") || hint.contains("evasive") || hint.contains("disappointed") || hint.contains("negotiating") {
            return VoiceProfile(
                rate: 0.43,
                pitch: 0.92,
                preferredLanguage: "en-GB",
                preferredIdentifierSubstrings: ["jamie", "lee", "evan", "daniel", "tom"]
            )
        }

        // Casual / breezy / older (landlord)
        // → Jamie too, but lighter and a touch faster so he sounds different from the manager
        if hint.contains("casual") || hint.contains("breezy") || hint.contains("older") {
            return VoiceProfile(
                rate: 0.48,
                pitch: 1.05,
                preferredLanguage: "en-GB",
                preferredIdentifierSubstrings: ["jamie", "lee", "aaron", "fred", "rishi"]
            )
        }

        return .default
    }
}
