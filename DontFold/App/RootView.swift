import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(UserSession.self) private var session
    @Environment(MenuState.self) private var menu

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .leading) {
            if session.isSignedIn {
                NavigationStack(path: $router.path) {
                    HomeScreen()
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .scenarioList:
                                ScenarioListScreen()
                            case .personaPicker(let scenario):
                                PersonaPickerScreen(scenario: scenario)
                            case .scenarioDetail(let scenario):
                                ScenarioDetailScreen(scenario: scenario)
                            case .challenge(let scenario):
                                ChallengeScreen(scenario: scenario)
                            case .result(let result):
                                ResultScreen(result: result)
                            }
                        }
                }
                drawerOverlay
            } else {
                AuthScreen()
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: - Drawer overlay

    @ViewBuilder
    private var drawerOverlay: some View {
        // Dim backdrop
        Color.black
            .opacity(menu.isOpen ? 0.35 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(menu.isOpen)
            .onTapGesture { menu.close() }

        // Slide-in drawer
        GeometryReader { proxy in
            let width = proxy.size.width * 0.85
            SideMenuView()
                .frame(width: width)
                .offset(x: menu.isOpen ? 0 : -width)
        }
        .ignoresSafeArea()
    }
}
