import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechRecognizer {
    enum State {
        case idle
        case authorizing
        case unauthorized(String)
        case listening
        case error(String)
    }

    var state: State = .idle
    var transcript: String = ""

    private let recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init(locale: Locale = .init(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        let speechAuth = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in cont.resume(returning: status) }
        }
        guard speechAuth == .authorized else {
            state = .unauthorized("Speech recognition not authorized.")
            return false
        }
        let micAuth: Bool = await withCheckedContinuation { cont in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in cont.resume(returning: granted) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in cont.resume(returning: granted) }
            }
        }
        if !micAuth {
            state = .unauthorized("Microphone not authorized.")
            return false
        }
        return true
    }

    func start() async throws {
        try await stop()
        transcript = ""
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable."])
        }
        let granted = await requestAuthorization()
        guard granted else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        self.request = req

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak req] buffer, _ in
            req?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        state = .listening

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if let error {
                    self.state = .error(error.localizedDescription)
                    try? await self.stop()
                }
            }
        }
    }

    @discardableResult
    func stop() async throws -> String {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        state = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }
}
