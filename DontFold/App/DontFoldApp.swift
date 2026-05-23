import SwiftUI

@main
struct DontFoldApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
