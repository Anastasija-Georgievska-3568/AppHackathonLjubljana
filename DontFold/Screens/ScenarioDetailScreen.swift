import SwiftUI

/// D1Detail — Brief screen.
/// Status row + × → SCENARIO eyebrow + "Saying No To Bridesmaid Duty." →
/// pink-fill goal card → scene card → ⚠ avoid this list → pink CTA pinned bottom.
struct ScenarioDetailScreen: View {
    let scenario: Scenario
    @Environment(Router.self) private var router

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    statusRow
                    title
                        .padding(.top, 6)
                    cardStack
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            startCTA
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var statusRow: some View {
        HStack {
            Text("02 · brief")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Spacer()
            Button { router.pop() } label: {
                GlyphChip(glyph: "×", filled: true, size: 26)
            }
            .buttonStyle(.plain)
        }
    }

    /// Title block: pink "SCENARIO 0n" eyebrow then a two-line display headline
    /// with the second clause in pink.
    private var title: some View {
        let (leadLine, accentLine) = splitTitle(scenario.title)
        let n = scenarioIndex
        return VStack(alignment: .leading, spacing: 6) {
            Text(String(format: "scenario %02d", n))
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
            VStack(alignment: .leading, spacing: -4) {
                Text(leadLine)
                    .font(DFFont.title(26))
                    .foregroundStyle(Theme.ink)
                    .tracking(-0.5)
                Text(accentLine + ".")
                    .font(DFFont.title(26))
                    .foregroundStyle(Theme.accent)
                    .tracking(-0.5)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cardStack: some View {
        VStack(spacing: 10) {
            // Your goal (pink-fill)
            GlassCard(highlighted: true) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("your goal")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                    Text(scenario.userGoal)
                        .font(DFFont.headline(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // The scene
            GlassCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("the scene")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                    Text(scenario.setup)
                        .font(DFFont.body(13))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // ⚠ avoid this
            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("⚠ avoid this")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.accent)
                        .trackedCaps(1.6)
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(scenario.pressureCues, id: \.self) { item in
                            Text("· " + item)
                                .font(DFFont.body(13))
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var startCTA: some View {
        Button {
            router.push(.challenge(scenario))
        } label: {
            GlassCard(padding: 12, highlighted: true) {
                Text("START → hold the line")
                    .font(DFFont.headline(15))
                    .trackedCaps(1.2)
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Split the scenario title into two visual lines for the brief headline.
    /// Falls back to (title, "") if no good break exists.
    private func splitTitle(_ title: String) -> (String, String) {
        // Prefer two-clause splits like "Saying No To Bridesmaid"
        let bridges: [String] = [" To ", " With ", " For ", " Mom ", " Him ", " A "]
        for bridge in bridges {
            if let range = title.range(of: bridge) {
                let before = String(title[..<range.upperBound])
                let after = String(title[range.upperBound...])
                if !after.isEmpty {
                    return (before.trimmingCharacters(in: .whitespaces), after)
                }
            }
        }
        // Fallback: split on last whitespace
        if let lastSpace = title.lastIndex(of: " ") {
            let head = String(title[..<lastSpace])
            let tail = String(title[title.index(after: lastSpace)...])
            return (head, tail)
        }
        return (title, "")
    }

    private var scenarioIndex: Int {
        (ScenarioCatalog.all.firstIndex(where: { $0.id == scenario.id }) ?? 0) + 1
    }
}
