import SwiftUI

/// D1Result — Feedback + score.
/// Layout mirrors the brief card: status row → centered scenario eyebrow →
/// huge score hero → verdict card → WHAT WORKED card → NEXT TIME card →
/// footer (PLAY AGAIN | SHARE).
struct ResultScreen: View {
    let result: SessionResult
    @Environment(Router.self) private var router

    @State private var heroAppeared = false
    @State private var verdictAppeared = false
    @State private var cardsAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    statusRow
                    scenarioEyebrow
                        .padding(.top, 4)
                    scoreHero
                    verdictCard
                    whatWorkedCard
                    nextTimeCard
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.05)) { heroAppeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) { verdictAppeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.5)) { cardsAppeared = true }
        }
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text("RESULT")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .tracking(1.0)
            Spacer()
        }
    }

    private var scenarioEyebrow: some View {
        Text("\(result.scenarioTitle.lowercased()) · \(dateLabel)")
            .font(DFFont.micro(10))
            .foregroundStyle(Theme.accent)
            .trackedCaps(1.6)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var scoreHero: some View {
        VStack(spacing: 4) {
            Text("confidence")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Text("\(Int(result.finalConfidence * 100))")
                .font(DFFont.display(72))
                .foregroundStyle(Theme.accent)
                .tracking(-1.0)
                .contentTransition(.numericText())
            Text("out of 100")
                .font(DFFont.micro(9))
                .foregroundStyle(Theme.textSecondary)
                .trackedCaps(1.6)
                .padding(.top, -2)
            scoreBar
                .padding(.top, 6)
            tierPill
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .opacity(heroAppeared ? 1 : 0)
        .offset(y: heroAppeared ? 0 : 16)
    }

    private var scoreBar: some View {
        let segments = 20
        let filled = max(0, min(segments, Int(round(result.finalConfidence * Double(segments)))))
        return HStack(spacing: 3) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i < filled ? Theme.accent : Theme.bg)
                    .frame(height: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Theme.ink, lineWidth: 1.2)
                    )
            }
        }
    }

    private var tierPill: some View {
        Text(tierLabel)
            .font(DFFont.micro(11))
            .foregroundStyle(tierColor)
            .trackedCaps(1.6)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.bg))
            .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.2))
    }

    private var tierLabel: String {
        switch result.finalConfidence {
        case ..<0.4: return "folded"
        case ..<0.7: return "mixed"
        default: return "confident"
        }
    }

    private var tierColor: Color {
        switch result.finalConfidence {
        case ..<0.4: return Theme.accent
        case ..<0.7: return Theme.ink
        default: return Theme.accent
        }
    }

    private var verdictCard: some View {
        GlassCard(highlighted: true, offsetShadow: true) {
            VStack(spacing: 8) {
                Text("VERDICT")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .tracking(1.0)
                Text(result.verdictTitle.uppercased())
                    .font(DFFont.title(verdictFontSize))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                if !result.verdictVibe.isEmpty {
                    Text(result.verdictVibe)
                        .font(DFFont.body(14))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(verdictAppeared ? 1 : 0)
        .offset(y: verdictAppeared ? 0 : 16)
    }

    private var verdictFontSize: CGFloat {
        let len = result.verdictTitle.count
        switch len {
        case 0...14: return 28
        case 15...22: return 24
        case 23...32: return 20
        default: return 18
        }
    }

    private var whatWorkedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT WORKED")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.accent)
                    .tracking(1.0)
                if result.goodMoments.isEmpty {
                    Text("nothing landed clean this round.")
                        .font(DFFont.body(13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.goodMoments, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✓")
                                    .font(DFFont.body(13))
                                    .foregroundStyle(Theme.accent)
                                Text(item)
                                    .font(DFFont.body(13))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 12)
    }

    private var nextTimeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("NEXT TIME")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .tracking(1.0)
                if result.improvementAreas.isEmpty {
                    Text("hold the line, you're already there.")
                        .font(DFFont.body(13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.improvementAreas, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("→")
                                    .font(DFFont.body(13))
                                    .foregroundStyle(Theme.ink)
                                Text(item)
                                    .font(DFFont.body(13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 12)
    }

    private var footer: some View {
        Button {
            router.popToRoot()
        } label: {
            GlassCard(padding: 12, highlighted: true) {
                Text("PLAY AGAIN")
                    .font(DFFont.headline(13))
                    .tracking(1.2)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: result.date).lowercased()
    }
}
