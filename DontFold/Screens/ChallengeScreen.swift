import SwiftUI

struct ChallengeScreen: View {
    let scenario: Scenario
    @Environment(Router.self) private var router

    @State private var session: ChallengeSession
    @State private var speech = SpeechRecognizer()
    @State private var inputText: String = ""
    @State private var calloutVisible: Bool = false
    @State private var sending: Bool = false
    @State private var endingSession: Bool = false
    @FocusState private var textFocused: Bool

    init(scenario: Scenario) {
        self.scenario = scenario
        _session = State(initialValue: ChallengeSession(scenario: scenario))
    }

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(intensity: 0.4 + session.pressure * 0.6)
            Color.black.opacity(session.pressure * 0.25).ignoresSafeArea()

            VStack(spacing: 14) {
                topBar
                metersRow

                ZStack(alignment: .top) {
                    conversation
                    if let callout = session.lastCallout, calloutVisible {
                        calloutBanner(callout)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)

                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await abort() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
            }
        }
        .task { await startSession() }
        .onChange(of: session.lastCallout) { _, newValue in
            guard newValue != nil else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                calloutVisible = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 3_200_000_000)
                withAnimation(.easeIn(duration: 0.4)) { calloutVisible = false }
            }
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack(spacing: 10) {
            Image(systemName: scenario.category.systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(scenario.category.tint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(scenario.category.tint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 1) {
                Text(scenario.title)
                    .font(DFFont.headline(15))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Turn \(session.userTurnCount + (session.phase == .userRecording || session.phase == .userTyping ? 1 : 0)) / \(session.maxTurns)")
                    .font(DFFont.micro(9))
                    .foregroundStyle(Theme.textMuted)
                    .trackedCaps()
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var metersRow: some View {
        HStack(spacing: 16) {
            PressureMeter(level: session.pressure)
            ConfidenceMeter(level: session.confidence)
        }
        .padding(.vertical, 4)
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(session.turns) { turn in
                        bubble(for: turn)
                            .id(turn.id)
                    }
                    if sending {
                        thinkingBubble
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.vertical, 4)
            }
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

    private func bubble(for turn: Turn) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if turn.speaker == .ai {
                aiAvatar
                GlassCard(cornerRadius: 22, padding: 16, strokeColor: scenario.category.tint.opacity(0.35)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(scenario.aiPersona.split(separator: "—").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? "AI")
                            .font(DFFont.micro(9))
                            .foregroundStyle(scenario.category.tint)
                            .trackedCaps()
                        if isLatestAI(turn) {
                            TypeOnText(text: turn.text)
                        } else {
                            Text(turn.text)
                                .font(DFFont.headline(18))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Spacer(minLength: 24)
            } else {
                Spacer(minLength: 24)
                VStack(alignment: .trailing, spacing: 6) {
                    Text("YOU")
                        .font(DFFont.micro(9))
                        .foregroundStyle(Theme.accent)
                        .trackedCaps()
                    Text(turn.text)
                        .font(DFFont.body(16))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(DFGradient.hero.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle().fill(
                LinearGradient(colors: [scenario.category.tint, scenario.difficulty.tint],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
    }

    private var thinkingBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            aiAvatar
            GlassCard(cornerRadius: 22, padding: 16) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Theme.textSecondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(thinkingScale(i: i))
                    }
                }
                .frame(height: 18)
            }
            Spacer(minLength: 24)
        }
        .transition(.opacity)
    }

    @State private var thinkingPhase: CGFloat = 0
    private func thinkingScale(i: Int) -> CGFloat {
        let offset = CGFloat(i) * 0.25
        let v = sin((thinkingPhase + offset) * .pi * 2)
        return 0.85 + 0.35 * (v * 0.5 + 0.5)
    }

    private func calloutBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.danger))
            VStack(alignment: .leading, spacing: 2) {
                Text("CALLED OUT")
                    .font(DFFont.micro(9))
                    .foregroundStyle(Theme.danger)
                    .trackedCaps()
                Text(text)
                    .font(DFFont.body(14))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.danger.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Theme.danger.opacity(0.3), radius: 12, y: 4)
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if case .userRecording = session.phase {
                liveTranscriptCard
            }
            HStack(spacing: 10) {
                TextField("type if speaking feels like too much…", text: $inputText, axis: .vertical)
                    .font(DFFont.body(15))
                    .foregroundStyle(.white)
                    .focused($textFocused)
                    .lineLimit(1...4)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .disabled(!canInput)
                    .onSubmit { Task { await sendTyped() } }

                if !inputText.isEmpty {
                    Button {
                        Task { await sendTyped() }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(DFGradient.hero))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: inputText.isEmpty)

            MicButton(
                isListening: session.phase == .userRecording,
                isDisabled: !canMic
            ) {
                Task { await toggleMic() }
            }
        }
    }

    private var liveTranscriptCard: some View {
        GlassCard(cornerRadius: 18, padding: 14, strokeColor: Theme.danger.opacity(0.45)) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Theme.danger)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 4) {
                    Text("LISTENING")
                        .font(DFFont.micro(9))
                        .foregroundStyle(Theme.danger)
                        .trackedCaps()
                    Text(speech.transcript.isEmpty ? "go on, say it." : speech.transcript)
                        .font(DFFont.body(15))
                        .foregroundStyle(.white)
                        .animation(.default, value: speech.transcript)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - State helpers

    private var canMic: Bool {
        switch session.phase {
        case .awaitingUser, .userRecording: return true
        default: return false
        }
    }

    private var canInput: Bool {
        switch session.phase {
        case .awaitingUser, .userTyping: return true
        default: return false
        }
    }

    private func isLatestAI(_ turn: Turn) -> Bool {
        guard let lastAI = session.turns.last(where: { $0.speaker == .ai }) else { return false }
        return lastAI.id == turn.id
    }

    // MARK: - Flow

    private func startSession() async {
        guard session.turns.isEmpty else { return }
        await runThinkingPulse()
        await nextAITurn()
    }

    private func runThinkingPulse() async {
        Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.linear(duration: 0.9)) { thinkingPhase += 1 }
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
        }
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
        do {
            let resp = try await GeminiService.shared.nextTurn(
                scenario: scenario,
                history: session.turns
            )
            session.applyDeltas(pressureDelta: resp.pressureDelta, confidenceDelta: resp.confidenceDelta)
            session.appendAI(resp.say, callout: resp.callout)
            session.phase = .aiSpeaking
            Task.detached { @MainActor in
                await TextToSpeech.shared.speak(resp.say, voiceHint: self.scenario.aiVoiceHint)
            }
            if resp.shouldEnd || session.userTurnCount >= session.maxTurns {
                try? await Task.sleep(nanoseconds: 900_000_000)
                await finalize()
            } else {
                session.phase = .awaitingUser
            }
        } catch {
            session.errorMessage = error.localizedDescription
            session.phase = .awaitingUser
        }
    }

    private func finalize() async {
        guard !endingSession else { return }
        endingSession = true
        sending = true
        do {
            let verdict = try await GeminiService.shared.finalVerdict(
                scenario: scenario,
                transcript: session.turns,
                finalPressure: session.pressure,
                finalConfidence: session.confidence
            )
            sending = false
            let result = SessionResult(
                scenarioTitle: scenario.title,
                scenarioId: scenario.id,
                verdictTitle: verdict.verdictTitle,
                verdictVibe: verdict.verdictVibe,
                oneLinerToShare: verdict.oneLinerToShare,
                highlights: verdict.highlights,
                stats: verdict.stats.map { ResultStat(label: $0.label, value: $0.value, detail: $0.detail) },
                finalPressure: session.pressure,
                finalConfidence: session.confidence,
                transcript: session.turns
            )
            await TextToSpeech.shared.stop()
            router.push(.result(result))
        } catch {
            sending = false
            session.errorMessage = error.localizedDescription
        }
    }

    private func abort() async {
        _ = try? await speech.stop()
        await TextToSpeech.shared.stop()
        router.pop()
    }
}
