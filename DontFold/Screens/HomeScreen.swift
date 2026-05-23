import SwiftUI

struct HomeScreen: View {
    @Environment(Router.self) private var router
    @State private var heroPhase: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(intensity: 1.0)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    heroCard
                    quickGrid
                    featuredSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 60)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DON'T")
                    .font(DFFont.title(36))
                    .foregroundStyle(.white)
                Text("FOLD.")
                    .font(DFFont.title(36))
                    .foregroundStyle(DFGradient.hero)
            }
            Spacer()
            Button {
                router.push(.scenarioList)
            } label: {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.10)))
                    .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var heroCard: some View {
        GlassCard(cornerRadius: 32, padding: 26) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 6) {
                    Chip(label: "DAILY DROP", systemImage: "bolt.fill", tint: Theme.accent)
                    Chip(label: "AI ON", systemImage: "waveform", tint: Theme.success)
                }
                Text("Can you make it through one awkward conversation without folding?")
                    .font(DFFont.display(34))
                    .foregroundStyle(.white)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Practice the moments that make you sweat. AI plays the other side. We score the spiral.")
                    .font(DFFont.body(15))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: "Start Challenge", systemImage: "play.fill") {
                    router.push(.scenarioList)
                }
                .padding(.top, 4)
            }
        }
    }

    private var quickGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Quick Pick", trailing: "shuffle.circle.fill")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ScenarioCategory.allCases.prefix(4), id: \.self) { cat in
                    Button {
                        if let first = ScenarioCatalog.by(category: cat).first {
                            router.push(.scenarioDetail(first))
                        } else {
                            router.push(.scenarioList)
                        }
                    } label: {
                        categoryTile(cat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryTile(_ cat: ScenarioCategory) -> some View {
        GlassCard(cornerRadius: 22, padding: 18, strokeColor: cat.tint.opacity(0.4)) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: cat.systemImage)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(cat.tint)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(cat.tint.opacity(0.18)))
                Text(cat.label)
                    .font(DFFont.headline(16))
                    .foregroundStyle(.white)
                Text("\(ScenarioCatalog.by(category: cat).count) scenarios")
                    .font(DFFont.micro(10))
                    .foregroundStyle(Theme.textMuted)
                    .trackedCaps()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Featured", trailing: "flame.fill")
            VStack(spacing: 12) {
                ForEach(ScenarioCatalog.featured(), id: \.id) { scenario in
                    Button {
                        router.push(.scenarioDetail(scenario))
                    } label: {
                        ScenarioRowCard(scenario: scenario)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionHeader(title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(DFFont.title(22))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: trailing)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 2)
    }
}

struct ScenarioRowCard: View {
    let scenario: Scenario

    var body: some View {
        GlassCard(cornerRadius: 24, padding: 16, strokeColor: scenario.category.tint.opacity(0.30)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(colors: [scenario.category.tint.opacity(0.6), scenario.difficulty.tint.opacity(0.4)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                    Image(systemName: scenario.category.systemImage)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(DFFont.headline(17))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(scenario.blurb)
                        .font(DFFont.body(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Chip(label: scenario.difficulty.label, tint: scenario.difficulty.tint)
                        DifficultyPip(difficulty: scenario.difficulty)
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

#Preview {
    HomeScreen()
        .environment(Router())
}
