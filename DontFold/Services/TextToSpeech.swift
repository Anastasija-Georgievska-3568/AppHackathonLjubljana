import Foundation
import AVFoundation

/// TTS pipeline: OpenAI `tts-1-hd` is the primary engine. AVSpeechSynthesizer is
/// kept as a last-resort fallback (no API key, network failure, invalid voice).
@MainActor
final class TextToSpeech: NSObject {
    static let shared = TextToSpeech()

    private let synth = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synth.delegate = self
    }

    /// Speak `text` using the OpenAI voice named in `voiceHint`. If the hint is
    /// nil/empty we default to `alloy`. Returns when playback finishes (or fails).
    func speak(_ text: String, voiceHint: String? = nil) async {
        let voice = Self.openAIVoice(from: voiceHint)
        if GeminiConfig.hasKey {
            do {
                let data = try await Self.fetchOpenAIAudio(text: text, voice: voice)
                await playAndWait(data)
                return
            } catch {
                #if DEBUG
                print("[TTS/OpenAI] \(error.localizedDescription) — falling back to AVSpeech")
                #endif
            }
        }
        await speakFallback(text)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        continuation?.resume()
        continuation = nil
    }

    // MARK: - OpenAI path

    private func playAndWait(_ data: Data) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true, options: [])

                let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
                player.delegate = self
                audioPlayer = player
                player.play()
            } catch {
                #if DEBUG
                print("[TTS/OpenAI] playback init failed: \(error.localizedDescription)")
                #endif
                continuation?.resume()
                continuation = nil
            }
        }
    }

    /// Calls the Cloudflare Worker proxy's `/tts` route. The real OpenAI key
    /// lives on the Worker as a secret — never in the app binary.
    private static func fetchOpenAIAudio(text: String, voice: String) async throws -> Data {
        let url = URL(string: "\(GeminiConfig.proxyBase)/tts")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(GeminiConfig.appToken, forHTTPHeaderField: "X-App-Token")
        req.timeoutInterval = 20

        let body: [String: String] = ["voice": voice, "input": text]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "ProxyTTS", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "No response"])
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "ProxyTTS", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body.prefix(200))"])
        }
        return data
    }

    /// Pulls a single OpenAI voice token out of the hint string. Hints are now
    /// just the voice name (e.g. `"alloy"`, `"marin"`); legacy comma-separated
    /// hints are tolerated by picking the first known voice token.
    private static func openAIVoice(from hint: String?) -> String {
        guard let raw = hint?.lowercased(), !raw.isEmpty else { return "alloy" }
        let parts = raw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if let trimmed = parts.first(where: { !$0.isEmpty }) {
            return trimmed
        }
        return "alloy"
    }

    // MARK: - AVSpeech fallback (minimal)

    private func speakFallback(_ text: String) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true, options: [])
            } catch { /* non-fatal */ }

            let utter = AVSpeechUtterance(string: text)
            utter.voice = AVSpeechSynthesisVoice(language: "en-US")
            utter.volume = 1.0
            synth.speak(utter)
        }
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

extension TextToSpeech: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.audioPlayer = nil
            self.continuation?.resume()
            self.continuation = nil
        }
    }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.audioPlayer = nil
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}
