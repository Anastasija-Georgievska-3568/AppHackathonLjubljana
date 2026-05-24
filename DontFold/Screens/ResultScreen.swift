import SwiftUI

struct ResultScreen: View {
    let result: SessionResult
    @Environment(Router.self) private var router

    @State private var titleAppeared = false
    @State private var statsAppeared = false
    @State private var highlightsAppeared = false

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(intensity: 0.9)

            ScrollView {
                VStack(spacing: 20) {
                    header
                    verdictHero
                    vibeLine
                    statsRow
                    highlightsCard
                    shareCardPreview
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }

            VStack {
                Spacer()
                bottomActions
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) { titleAppeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.5)) { statsAppeared = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.9)) { highlightsAppeared = true }
        }
    }

    private var header: some View {
        HStack {
            Text("RECAP")
                .font(DFFont.micro(11))
                .foregroundStyle(Theme.textSecondary)
                .trackedCaps(1.8)
            Spacer()
            Button { router.popToRoot() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
        }
        .padding(.top, 4)
    }

    private var verdictHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.scenarioTitle)
                .font(DFFont.micro(11))
                .foregroundStyle(Theme.textMuted)
                .trackedCaps(1.6)
                .lineLimit(2)
            Text(result.verdictTitle.uppercased())
                .font(DFFont.display(verdictTitleFontSize))
                .foregroundStyle(DFGradient.hero)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.55)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Auto-shrink the verdict title for longer text so it doesn't wrap into chaos.
    private var verdictTitleFontSize: CGFloat {
        let len = result.verdictTitle.count
        switch len {
        case 0...14: return 52
        case 15...22: return 44
        case 23...32: return 36
        default: return 30
        }
    }

    private var vibeLine: some View {
        Text(result.verdictVibe)
            .font(DFFont.headline(17))
            .foregroundStyle(.white)
            .lineSpacing(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(titleAppeared ? 1 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                statCard(label: "PRESSURE", value: "\(Int(result.finalPressure * 100))", tint: Theme.danger)
                statCard(label: "CONFIDENCE", value: "\(Int(result.finalConfidence * 100))", tint: Theme.success)
                ForEach(result.stats, id: \.label) { stat in
                    statCard(label: stat.label, value: stat.value, detail: stat.detail, tint: Theme.accent2)
                }
            }
        }
        .opacity(statsAppeared ? 1 : 0)
        .offset(y: statsAppeared ? 0 : 16)
    }

    private func statCard(label: String, value: String, detail: String? = nil, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(DFFont.micro(9))
                .foregroundStyle(tint)
                .trackedCaps()
            Text(value)
                .font(DFFont.display(32))
                .foregroundStyle(.white)
            if let detail {
                Text(detail)
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.textMuted)
                    .trackedCaps()
            }
        }
        .frame(width: 130, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }

    private var highlightsCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("MOMENTS")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.textSecondary)
                    .trackedCaps()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(result.highlights.enumerated()), id: \.offset) { idx, line in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(idx + 1)")
                                .font(DFFont.mono(13))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 22, alignment: .leading)
                            Text(line)
                                .font(DFFont.body(15))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .opacity(highlightsAppeared ? 1 : 0)
        .offset(y: highlightsAppeared ? 0 : 16)
    }

    private var shareCardPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR DROP")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.textMuted)
                .trackedCaps()
            Button {
                router.push(.share(result))
            } label: {
                ShareCardView(result: result, isCompact: true)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Theme.strokeHi, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .opacity(highlightsAppeared ? 1 : 0)
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.95)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 30)
            HStack(spacing: 10) {
                GhostButton(title: "Run It Back", systemImage: "arrow.counterclockwise") {
                    router.popToRoot()
                }
                PrimaryButton(title: "Share", systemImage: "square.and.arrow.up") {
                    router.push(.share(result))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
            .padding(.top, 8)
            .background(Theme.bg.opacity(0.95))
        }
    }
}
