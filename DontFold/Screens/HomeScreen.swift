import SwiftUI

/// D1Home — Hot Girl CEO direction.
/// Wordmark "DON'T / FOLD." → "pick your hard convo →" → scenario card stack.
struct HomeScreen: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    wordmark
                        .padding(.top, 12)

                    Text("pick your hard convo →")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                        .padding(.top, 18)

                    scenarioStack
                        .padding(.top, 10)

                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var wordmark: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scenarioStack: some View {
        VStack(spacing: 8) {
            ForEach(ScenarioCatalog.all, id: \.id) { scenario in
                if scenario.comingSoon {
                    ScenarioRowCard(scenario: scenario)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                } else {
                    Button {
                        if scenario.personas != nil {
                            router.push(.personaPicker(scenario))
                        } else {
                            router.push(.scenarioDetail(scenario))
                        }
                    } label: {
                        ScenarioRowCard(scenario: scenario)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ScenarioRowCard: View {
    let scenario: Scenario

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(scenario.title)
                        .font(DFFont.headline(15))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    arrowOrTag
                }
                Text(scenario.blurb)
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let personas = scenario.personas, !personas.isEmpty, !scenario.comingSoon {
                    Text(personaBadgeText(count: personas.count))
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.textSecondary)
                        .trackedCaps(1.6)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func personaBadgeText(count: Int) -> String {
        let type = scenario.personaTypeLabel
        return type.isEmpty ? "\(count) personas" : "\(count) \(type) personas"
    }

    @ViewBuilder
    private var arrowOrTag: some View {
        if scenario.comingSoon {
            Text("coming soon")
                .font(DFFont.micro(9))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
        } else {
            Text("↗")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Theme.accent)
        }
    }
}

#Preview {
    HomeScreen()
        .environment(Router())
}
