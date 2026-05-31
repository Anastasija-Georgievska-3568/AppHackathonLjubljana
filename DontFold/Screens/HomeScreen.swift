import SwiftUI

/// D1Home — Hot Girl CEO direction.
/// Status row → DON'T / FOLD. wordmark + "♡ girlies edition" scribble →
/// "pick your hard convo →" → scenario card stack → 🔥 streak + scribble.
struct HomeScreen: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    statusRow
                        .padding(.top, 4)

                    wordmark
                        .padding(.top, 10)

                    Text("pick your hard convo →")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                        .padding(.top, 18)

                    scenarioStack
                        .padding(.top, 10)

                    Color.clear.frame(height: 80) // footer breathing room
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text("01 · home")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Spacer()
            Text("⚙")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
    }

    private var wordmark: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: -8) {
                Text("DON'T")
                    .font(DFFont.display(46))
                    .foregroundStyle(Theme.ink)
                    .tracking(-1.0)
                Text("FOLD.")
                    .font(DFFont.display(46))
                    .foregroundStyle(Theme.accent)
                    .tracking(-1.0)
            }
            ScribbleTag(text: "♡ girlies edition", rotation: -6, color: Theme.accent, size: 13)
                .offset(x: 0, y: -16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scenarioStack: some View {
        VStack(spacing: 8) {
            ForEach(Array(ScenarioCatalog.all.enumerated()), id: \.element.id) { idx, scenario in
                Button {
                    router.push(.scenarioDetail(scenario))
                } label: {
                    ScenarioRowCard(scenario: scenario, highlighted: idx == 0)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack {
            Chip(label: "5-day streak", systemImage: "flame.fill")
            Spacer()
            ScribbleTag(text: "\u{201C}don't be normal\u{201D}", rotation: -4, color: Theme.accent, size: 14)
        }
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg, Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.horizontal, -16)
        )
    }
}

struct ScenarioRowCard: View {
    let scenario: Scenario
    var highlighted: Bool = false

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12, highlighted: highlighted) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(scenario.title)
                        .font(DFFont.headline(15))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    GlyphChip(glyph: "↗", filled: true, size: 24)
                }
                Text(scenario.blurb)
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    HomeScreen()
        .environment(Router())
}
