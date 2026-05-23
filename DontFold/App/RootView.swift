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
                    case .scenarioDetail(let scenario):
                        ScenarioDetailScreen(scenario: scenario)
                    case .challenge(let scenario):
                        ChallengeScreen(scenario: scenario)
                    case .result(let result):
                        ResultScreen(result: result)
                    case .share(let result):
                        ShareCardScreen(result: result)
                    }
                }
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}
