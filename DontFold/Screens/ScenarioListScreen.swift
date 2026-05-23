import SwiftUI

struct ScenarioListScreen: View {
    @Environment(Router.self) private var router
    @State private var selectedCategory: ScenarioCategory? = nil

    var filtered: [Scenario] {
        guard let selectedCategory else { return ScenarioCatalog.all }
        return ScenarioCatalog.by(category: selectedCategory)
    }

    var body: some View {
        ZStack {
            AnimatedAuroraBackground(intensity: 0.6)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleBlock
                    filterBar
                    LazyVStack(spacing: 12) {
                        ForEach(filtered, id: \.id) { scenario in
                            Button {
                                router.push(.scenarioDetail(scenario))
                            } label: {
                                ScenarioRowCard(scenario: scenario)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
                .padding(.bottom, 40)
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

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PICK YOUR PRESSURE")
                .font(DFFont.micro(11))
                .foregroundStyle(Theme.textSecondary)
                .trackedCaps(1.8)
            Text("Choose the moment.")
                .font(DFFont.title(34))
                .foregroundStyle(.white)
        }
        .padding(.top, 4)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(label: "All", systemImage: "sparkles", isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }
                ForEach(ScenarioCategory.allCases, id: \.self) { cat in
                    filterPill(label: cat.label, systemImage: cat.systemImage, isSelected: selectedCategory == cat, tint: cat.tint) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedCategory = cat
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterPill(label: String, systemImage: String, isSelected: Bool, tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .black))
                Text(label)
                    .font(DFFont.micro(12))
                    .trackedCaps(1.2)
            }
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(isSelected ? tint.opacity(0.35) : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule().stroke(isSelected ? tint.opacity(0.65) : Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
