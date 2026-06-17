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
         let granted = await requestAuthorization()
        guard granted else { return }

        guard let recognizer else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable for this locale."])
        }

        // `isAvailable` flips to true asynchronously after authorization, once
        // the recognizer connects to the speech service. Wait briefly for it
        // instead of failing on the first instant.
        if !recognizer.isAvailable {
            for _ in 0..<10 where !recognizer.isAvailable {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s, up to 1s total
            }
        }
        guard recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable. Check your network connection, or run on a real device."])
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        // Prefer on-device recognition when supported: works offline and avoids
        // the server round-trip that fails when unavailable/offline.
        if recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
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
                    // Suppress noisy spurious errors that iOS itself logs as
                    // "Ignoring subsequent local speech recording error".
                    let ns = error as NSError
                    let isSpurious = ns.domain == "kAFAssistantErrorDomain" && (ns.code == 1101 || ns.code == 203 || ns.code == 216)
                    if !isSpurious {
                        self.state = .error(error.localizedDescription)
                    }
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
