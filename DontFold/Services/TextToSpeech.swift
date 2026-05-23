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
            let utter = AVSpeechUtterance(string: text)
            utter.rate = 0.50
            utter.pitchMultiplier = 1.0
            utter.voice = Self.pickVoice(hint: voiceHint)
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

    private static func pickVoice(hint: String?) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
        if let hint = hint?.lowercased() {
            if hint.contains("warm") || hint.contains("friendly") {
                return voices.first { $0.identifier.contains("samantha") } ?? AVSpeechSynthesisVoice(language: "en-US")
            }
            if hint.contains("clipped") || hint.contains("fast") {
                return voices.first { $0.identifier.contains("karen") || $0.identifier.contains("daniel") } ?? AVSpeechSynthesisVoice(language: "en-GB")
            }
            if hint.contains("calm") || hint.contains("measured") {
                return voices.first { $0.identifier.contains("daniel") || $0.identifier.contains("oliver") } ?? AVSpeechSynthesisVoice(language: "en-GB")
            }
            if hint.contains("older") || hint.contains("casual") {
                return voices.first { $0.identifier.contains("aaron") } ?? AVSpeechSynthesisVoice(language: "en-US")
            }
        }
        return AVSpeechSynthesisVoice(language: "en-US")
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
