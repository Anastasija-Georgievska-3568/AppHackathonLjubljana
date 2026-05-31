import SwiftUI

/// The Hot Girl CEO Home is itself the scenario picker — there is no
/// separate "list" screen in this direction. This view is kept to satisfy the
/// `.scenarioList` route and renders the same scenario stack, so any deep
/// link still lands somewhere on-brand.
struct ScenarioListScreen: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("pick your hard convo →")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                        .padding(.top, 4)

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
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { router.pop() } label: {
                    GlyphChip(glyph: "×", filled: false, size: 26)
                }
            }
        }
    }
}
