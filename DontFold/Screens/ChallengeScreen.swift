import SwiftUI

/// D1Convo — Live conversation screen.
/// Header: "LIVE · TURN n/N" + bold scenario title + × chip.
/// Two segmented meters (PRESSURE pink, CONFIDENCE ink).
/// Alternating bubbles: them (gray, pink avatar dot) / you (pink, white text).
/// Footer: dashed input pill + circular pink mic. Voice is primary.
struct ChallengeScreen: View {
    let scenario: Scenario
    @Environment(Router.self) private var router

    @State private var session: ChallengeSession
    @State private var speech = SpeechRecognizer()
    @State private var inputText: String = ""
    @State private var sending: Bool = false
    @State private var endingSession: Bool = false
    @FocusState private var textFocused: Bool

    init(scenario: Scenario) {
        self.scenario = scenario
        _session = State(initialValue: ChallengeSession(scenario: scenario))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 10) {
                header
                metersRow
                errorBanner
                conversation
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await startSession() }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("live · turn \(currentTurnDisplay)/\(session.maxTurns)")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .trackedCaps(1.6)
                Text(scenario.title)
                    .font(DFFont.headline(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                Task { await abort() }
            } label: {
                GlyphChip(glyph: "×", filled: false, size: 26)
            }
            .buttonStyle(.plain)
        }
    }

    private var currentTurnDisplay: Int {
        let inProgress = session.phase == .userRecording || session.phase == .userTyping
        return min(session.maxTurns, session.userTurnCount + (inProgress ? 1 : 0))
    }

    private var metersRow: some View {
        HStack(spacing: 10) {
            PressureMeter(level: session.pressure).frame(maxWidth: .infinity, alignment: .leading)
            ConfidenceMeter(level: session.confidence).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let message = session.errorMessage {
            HStack(alignment: .top, spacing: 8) {
                Text("⚠")
                    .font(DFFont.micro(12))
                    .foregroundStyle(Theme.accent)
                Text(message)
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button { session.errorMessage = nil } label: {
                    Text("×")
                        .font(DFFont.headline(14))
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.bgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.ink, lineWidth: 1.5)
            )
        }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(session.turns) { turn in
                        bubble(for: turn)
                            .id(turn.id)
                    }
                    if sending {
                        composingBubble
                            .id("composing")
                    }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.top, 8)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: session.turns.count) { _, _ in
                withAnimation(.spring(response: 0.4)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: sending) { _, _ in
                withAnimation(.spring(response: 0.4)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func bubble(for turn: Turn) -> some View {
        if turn.speaker == .ai {
            HStack(alignment: .top, spacing: 6) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 18, height: 18)
                themBubble(text: turn.text)
                Spacer(minLength: 28)
            }
        } else {
            HStack {
                Spacer(minLength: 28)
                youBubble(text: turn.text)
            }
        }
    }

    private func themBubble(text: String) -> some View {
        Text(text)
            .font(DFFont.body(16))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.bubbleGray)
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    private func youBubble(text: String) -> some View {
        Text(text)
            .font(DFFont.body(16))
            .foregroundStyle(.white)
            .multilineTextAlignment(.trailing)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.accent)
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Dashed light-pink "...typing" bubble — shown while the AI's reply is
    /// resolving. Matches the wireframe's dashed pink composing bubble.
    private var composingBubble: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 18, height: 18)
            Text("...typing")
                .font(DFFont.body(16))
                .foregroundStyle(Theme.ink.opacity(0.5))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.accent3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .foregroundStyle(Theme.ink)
                )
            Spacer(minLength: 28)
        }
        .transition(.opacity)
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if case .userRecording = session.phase {
                liveTranscriptRow
            }
            HStack(spacing: 8) {
                inputPill
                if !inputText.isEmpty {
                    Button {
                        Task { await sendTyped() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Theme.accent)
                                .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    MicButton(
                        isListening: session.phase == .userRecording,
                        isDisabled: !canMic
                    ) {
                        Task { await toggleMic() }
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: inputText.isEmpty)
        }
    }

    private var inputPill: some View {
        TextField("type if speaking feels like too much…", text: $inputText, axis: .vertical)
            .font(DFFont.body(15))
            .foregroundStyle(Theme.ink)
            .tint(Theme.accent)
            .focused($textFocused)
            .lineLimit(1...3)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(Theme.bg)
            )
            .overlay(
                Capsule()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundStyle(Theme.ink)
            )
            .disabled(!canInput)
            .onSubmit { Task { await sendTyped() } }
            .frame(maxWidth: .infinity)
    }

    private var liveTranscriptRow: some View {
        GlassCard(cornerRadius: 12, padding: 10) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 2) {
                    Text("listening")
                        .font(DFFont.micro(9))
                        .foregroundStyle(Theme.accent)
                        .trackedCaps(1.6)
                    Text(speech.transcript.isEmpty ? "go on, say it." : speech.transcript)
                        .font(DFFont.body(16))
                        .foregroundStyle(Theme.ink)
                        .animation(.default, value: speech.transcript)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - State helpers

    private var canMic: Bool {
        switch session.phase {
        case .awaitingUser, .userRecording: true
        default: false
        }
    }

    private var canInput: Bool {
        switch session.phase {
        case .awaitingUser, .userTyping: true
        default: false
        }
    }

    // MARK: - Flow

    private func startSession() async {
        guard session.turns.isEmpty else { return }
        await nextAITurn()
    }

    private func toggleMic() async {
        if session.phase == .userRecording {
            let text = (try? await speech.stop()) ?? ""
            session.phase = .sending
            await sendUserText(text)
        } else {
            do {
                try await speech.start()
                session.phase = .userRecording
            } catch {
                session.errorMessage = error.localizedDescription
            }
        }
    }

    private func sendTyped() async {
        let text = inputText
        inputText = ""
        textFocused = false
        if session.phase == .userRecording {
            _ = try? await speech.stop()
        }
        session.phase = .sending
        await sendUserText(text)
    }

    private func sendUserText(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            session.phase = .awaitingUser
            return
        }
        session.appendUser(text)
        await nextAITurn()
    }

    private func nextAITurn() async {
        sending = true
        defer { sending = false }
        let isFinalTurn = session.userTurnCount >= session.maxTurns && !session.turns.isEmpty
        do {
            let resp = try await GeminiService.shared.nextTurn(
                scenario: scenario,
                history: session.turns,
                isFinalTurn: isFinalTurn
            )
            session.applyDeltas(pressureDelta: resp.pressureDelta, confidenceDelta: resp.confidenceDelta)
            session.appendAI(resp.say, callout: resp.callout)
            session.phase = .aiSpeaking

            let isFinal = resp.shouldEnd || session.userTurnCount >= session.maxTurns
            if isFinal {
                async let tts: Void = TextToSpeech.shared.speak(resp.say, voiceHint: scenario.aiVoiceHint)
                async let verdictTask = preflightVerdict()
                _ = await tts
                try? await Task.sleep(nanoseconds: 700_000_000)
                let verdict = await verdictTask
                await navigateToResult(with: verdict)
            } else {
                Task.detached { @MainActor in
                    await TextToSpeech.shared.speak(resp.say, voiceHint: self.scenario.aiVoiceHint)
                }
                session.phase = .awaitingUser
            }
        } catch {
            session.errorMessage = error.localizedDescription
            session.phase = .awaitingUser
        }
    }

    private func preflightVerdict() async -> AIVerdict {
        do {
            return try await GeminiService.shared.finalVerdict(
                scenario: scenario,
                transcript: session.turns,
                finalPressure: session.pressure,
                finalConfidence: session.confidence
            )
        } catch {
            session.errorMessage = "Verdict fallback: \(error.localizedDescription)"
            return MockGemini.finalVerdict(
                scenario: scenario,
                transcript: session.turns,
                finalPressure: session.pressure,
                finalConfidence: session.confidence
            )
        }
    }

    private func navigateToResult(with verdict: AIVerdict) async {
        guard !endingSession else { return }
        endingSession = true
        let result = SessionResult(
            scenarioTitle: scenario.title,
            scenarioId: scenario.id,
            verdictTitle: verdict.verdictTitle.isEmpty
                ? VerdictTemplates.fallback(pressure: session.pressure, confidence: session.confidence)
                : verdict.verdictTitle,
            verdictVibe: verdict.verdictVibe,
            oneLinerToShare: verdict.oneLinerToShare,
            highlights: verdict.highlights,
            stats: verdict.stats.map { ResultStat(label: $0.label, value: $0.value, detail: $0.detail) },
            finalPressure: session.pressure,
            finalConfidence: session.confidence,
            transcript: session.turns
        )
        router.push(.result(result))
    }

    private func abort() async {
        _ = try? await speech.stop()
        await TextToSpeech.shared.stop()
        router.pop()
    }
}
