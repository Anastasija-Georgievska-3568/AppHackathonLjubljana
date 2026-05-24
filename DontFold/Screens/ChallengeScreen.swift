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
                errorBanner
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
                try? await Task.sleep(nanoseconds: 7_500_000_000)
                withAnimation(.easeOut(duration: 0.8)) { calloutVisible = false }
            }
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [scenario.category.tint.opacity(0.35), scenario.category.tint.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle().stroke(scenario.category.tint.opacity(0.45), lineWidth: 1)
                Image(systemName: scenario.category.systemImage)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(scenario.category.tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.title)
                    .font(DFFont.headline(15))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("Turn \(currentTurnDisplay)")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.textSecondary)
                        .trackedCaps(1.4)
                    Text("·")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.textMuted)
                    Text("of \(session.maxTurns)")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.textMuted)
                        .trackedCaps(1.4)
                }
            }
            Spacer()
            modeBadge
        }
        .padding(.vertical, 6)
    }

    private var currentTurnDisplay: Int {
        let inProgress = session.phase == .userRecording || session.phase == .userTyping
        return min(session.maxTurns, session.userTurnCount + (inProgress ? 1 : 0))
    }

    private var modeBadge: some View {
        let live = GeminiConfig.hasKey
        return HStack(spacing: 5) {
            Circle()
                .fill(live ? Theme.success : Theme.warning)
                .frame(width: 6, height: 6)
                .shadow(color: (live ? Theme.success : Theme.warning).opacity(0.7), radius: 4)
            Text(live ? "LIVE" : "DEMO")
                .font(DFFont.micro(9))
                .foregroundStyle(live ? Theme.success : Theme.warning)
                .trackedCaps(1.6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.04))
        )
        .overlay(
            Capsule().stroke((live ? Theme.success : Theme.warning).opacity(0.35), lineWidth: 1)
        )
    }

    private var errorBanner: some View {
        Group {
            if let message = session.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.danger))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI ERROR")
                            .font(DFFont.micro(9))
                            .foregroundStyle(Theme.danger)
                            .trackedCaps()
                        Text(message)
                            .font(DFFont.body(13))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button {
                        session.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.bgElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.danger.opacity(0.5), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
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
        HStack(alignment: .top, spacing: 10) {
            if turn.speaker == .ai {
                aiAvatar
                ZStack(alignment: .leading) {
                    GlassCard(cornerRadius: 24, padding: 18, strokeColor: scenario.category.tint.opacity(0.30)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(scenario.aiPersona.split(separator: "—").first.map(String.init)?.trimmingCharacters(in: .whitespaces).uppercased() ?? "AI")
                                .font(DFFont.micro(9))
                                .foregroundStyle(scenario.category.tint)
                                .trackedCaps(1.6)
                            if isLatestAI(turn) {
                                TypeOnText(text: turn.text, font: DFFont.headline(19))
                            } else {
                                Text(turn.text)
                                    .font(DFFont.headline(19))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    // accent stripe — persona color
                    Capsule()
                        .fill(scenario.category.tint)
                        .frame(width: 3)
                        .padding(.vertical, 14)
                        .padding(.leading, 0)
                }
                Spacer(minLength: 28)
            } else {
                Spacer(minLength: 28)
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("YOU")
                            .font(DFFont.micro(9))
                            .foregroundStyle(Theme.accent)
                            .trackedCaps(1.6)
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 4, height: 4)
                    }
                    Text(turn.text)
                        .font(DFFont.body(16))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Theme.accent.opacity(0.18))
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Theme.accent.opacity(0.45), lineWidth: 1)
                        )
                        .shadow(color: Theme.accent.opacity(0.25), radius: 18, x: 0, y: 6)
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
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Theme.danger)
                Image(systemName: "eye.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
            .shadow(color: Theme.danger.opacity(0.5), radius: 8, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("CALLED OUT")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.danger)
                    .trackedCaps(1.8)
                Text(text)
                    .font(DFFont.headline(15))
                    .foregroundStyle(.white)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.danger.opacity(0.10))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Theme.danger.opacity(0.7), Theme.accent.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Theme.danger.opacity(0.40), radius: 18, y: 6)
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
        // The user has just spoken their Nth turn — if N equals maxTurns, this
        // upcoming AI response is the FINAL line of the scene. We signal that
        // to Gemini so it delivers a definitive outcome instead of another question.
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

        let verdict: AIVerdict
        do {
            verdict = try await GeminiService.shared.finalVerdict(
                scenario: scenario,
                transcript: session.turns,
                finalPressure: session.pressure,
                finalConfidence: session.confidence
            )
        } catch {
            // Verdict call failed — surface the error briefly, then fall back to
            // a locally-built verdict so the user always reaches the result screen.
            session.errorMessage = "Verdict fallback: \(error.localizedDescription)"
            verdict = MockGemini.finalVerdict(
                scenario: scenario,
                transcript: session.turns,
                finalPressure: session.pressure,
                finalConfidence: session.confidence
            )
        }

        sending = false
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
        await TextToSpeech.shared.stop()
        router.push(.result(result))
    }

    private func abort() async {
        _ = try? await speech.stop()
        await TextToSpeech.shared.stop()
        router.pop()
    }
}
