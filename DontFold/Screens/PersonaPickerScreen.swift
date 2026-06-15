import SwiftUI

/// PersonaPicker — appears between the Home scenario stack and the Brief screen
/// whenever a scenario ships with multiple personas. Visually echoes the Home
/// card stack so the flow feels like a natural second deal of cards.
struct PersonaPickerScreen: View {
    let scenario: Scenario
    @Environment(Router.self) private var router

    private var personas: [Persona] { scenario.personas ?? [] }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    backRow
                    title
                        .padding(.top, 6)
                    Text("choose your manager's persona →")
                        .font(DFFont.micro(10))
                        .foregroundStyle(Theme.ink)
                        .trackedCaps(1.6)
                        .padding(.top, 4)
                    personaStack
                    Color.clear.frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var backRow: some View {
        HStack {
            HamburgerButton()
            Spacer()
            Button { router.pop() } label: {
                Text("←")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("scenario")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
            Text(scenario.title.lowercased())
                .font(DFFont.title(26))
                .foregroundStyle(Theme.ink)
                .tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var personaStack: some View {
        VStack(spacing: 8) {
            ForEach(personas, id: \.id) { persona in
                Button {
                    router.push(.scenarioDetail(scenario.resolved(with: persona)))
                } label: {
                    PersonaRowCard(persona: persona)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PersonaRowCard: View {
    let persona: Persona

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(persona.label)
                        .font(DFFont.headline(15))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text("↗")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Theme.accent)
                }
                Text(persona.description)
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PersonaPickerScreen(scenario: ScenarioCatalog.all.first!)
        .environment(Router())
        .environment(MenuState())
}
