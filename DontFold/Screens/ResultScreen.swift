import SwiftUI

/// D1Result — Result + share screen.
/// Status row "10 · RESULT" + "SHARE ↗" → centered DON'T / FOLD. wordmark
/// → pink VERDICT card → two stat cards (PRESSURE ink, CONFIDENCE pink-fill)
/// → footer "SAVE IMAGE ✦ POST IT ✦ AGAIN".
struct ResultScreen: View {
    let result: SessionResult
    @Environment(Router.self) private var router

    @State private var heroAppeared = false
    @State private var verdictAppeared = false
    @State private var statsAppeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    statusRow
                    hero
                        .padding(.top, 8)
                    verdictCard
                    statsRow
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
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.35)) { verdictAppeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.6)) { statsAppeared = true }
        }
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text("10 · result")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Spacer()
            Button { router.push(.share(result)) } label: {
                Text("share ↗")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .trackedCaps(1.6)
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Text("your drop · \(dateLabel)")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
            VStack(spacing: -10) {
                Text("DON'T")
                    .font(DFFont.display(54))
                    .foregroundStyle(Theme.ink)
                    .tracking(-1.0)
                Text("FOLD.")
                    .font(DFFont.display(54))
                    .foregroundStyle(Theme.accent)
                    .tracking(-1.0)
            }
            Text(result.scenarioTitle)
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .opacity(heroAppeared ? 1 : 0)
        .offset(y: heroAppeared ? 0 : 12)
    }

    private var verdictCard: some View {
        GlassCard(highlighted: true, offsetShadow: true) {
            VStack(spacing: 6) {
                Text("verdict")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .trackedCaps(1.6)
                Text(verdictDisplay)
                    .font(DFFont.title(verdictFontSize))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-2)
                    .tracking(-0.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
        .opacity(verdictAppeared ? 1 : 0)
        .offset(y: verdictAppeared ? 0 : 16)
    }

    private var verdictDisplay: String {
        // Title-cased: "HOT GIRL HELD HER GROUND" — wraps naturally.
        result.verdictTitle.uppercased()
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

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(label: "pressure",
                     value: Int(result.finalPressure * 100),
                     highlighted: false)
            statCard(label: "confidence",
                     value: Int(result.finalConfidence * 100),
                     highlighted: true)
        }
        .opacity(statsAppeared ? 1 : 0)
        .offset(y: statsAppeared ? 0 : 12)
    }

    private func statCard(label: String, value: Int, highlighted: Bool) -> some View {
        GlassCard(highlighted: highlighted) {
            VStack(spacing: 2) {
                Text(label)
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.ink)
                    .trackedCaps(1.6)
                Text("\(value)")
                    .font(DFFont.title(30))
                    .foregroundStyle(highlighted ? Theme.accent : Theme.ink)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var footer: some View {
        Button {
            router.push(.share(result))
        } label: {
            GlassCard(padding: 10) {
                Text("SAVE IMAGE ✦ POST IT ✦ AGAIN")
                    .font(DFFont.headline(13))
                    .trackedCaps(1.2)
                    .foregroundStyle(Theme.ink)
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
