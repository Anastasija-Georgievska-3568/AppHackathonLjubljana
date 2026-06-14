import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
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
        .background(Theme.bg.ignoresSafeArea())
    }
}
