import SwiftUI

enum Route: Hashable {
    case scenarioList
    case personaPicker(Scenario)
    case scenarioDetail(Scenario)
    case challenge(Scenario)
    case result(SessionResult)
    case share(SessionResult)
}

@Observable
final class Router {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
