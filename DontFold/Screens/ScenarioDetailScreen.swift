import SwiftUI

struct ScenarioDetailScreen: View {
    let scenario: Scenario
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(intensity: 0.85)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    setupCard
                    goalCard
                    cuesGrid
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            VStack {
                Spacer()
                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Chip(label: scenario.category.label, systemImage: scenario.category.systemImage, tint: scenario.category.tint)
                Chip(label: scenario.difficulty.label.uppercased(), systemImage: "flame.fill", tint: scenario.difficulty.tint)
            }
            Text(scenario.title)
                .font(DFFont.display(40))
                .foregroundStyle(.white)
                .lineSpacing(-6)
                .fixedSize(horizontal: false, vertical: true)
            Text(scenario.blurb)
                .font(DFFont.body(16))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var setupCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("THE SCENE")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.textSecondary)
                    .trackedCaps()
                Text(scenario.setup)
                    .font(DFFont.body(15))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var goalCard: some View {
        GlassCard(cornerRadius: 24, strokeColor: Theme.accent.opacity(0.45)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR GOAL")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.accent)
                    .trackedCaps()
                Text(scenario.userGoal)
                    .font(DFFont.headline(20))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var cuesGrid: some View {
        VStack(spacing: 12) {
            cueCard(
                title: "WHAT MAKES THE METER SPIKE",
                items: scenario.pressureCues,
                tint: Theme.danger,
                icon: "exclamationmark.triangle.fill"
            )
            cueCard(
                title: "WHAT EARNS YOU CONFIDENCE",
                items: scenario.confidenceCues,
                tint: Theme.success,
                icon: "checkmark.seal.fill"
            )
        }
    }

    private func cueCard(title: String, items: [String], tint: Color, icon: String) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(DFFont.micro(10))
                        .foregroundStyle(tint)
                        .trackedCaps()
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(tint.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(item)
                                .font(DFFont.body(14))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)

            VStack(spacing: 10) {
                PrimaryButton(title: "Begin Challenge", systemImage: "bolt.fill") {
                    router.push(.challenge(scenario))
                }
                Text("Voice or text. Up to 8 turns. Don't fold.")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.textMuted)
                    .trackedCaps(1.4)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
            .padding(.top, 8)
            .background(Theme.bg.opacity(0.95))
        }
    }
}
