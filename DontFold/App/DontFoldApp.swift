import SwiftUI

@main
struct DontFoldApp: App {
    @State private var router = Router()
    @State private var session = UserSession()
    @State private var menu = MenuState()
    @State private var ledger: any BillingLedger = LocalBillingLedger()
    @State private var history = SessionHistoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(session)
                .environment(menu)
                .environment(history)
                .environment(LedgerBox(ledger: ledger))
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

/// Thin wrapper to inject a protocol-typed observable into the environment.
/// SwiftUI's `.environment` needs a concrete type; this lets us swap
/// LocalBillingLedger for a future RemoteBillingLedger without rewiring.
@Observable
@MainActor
final class LedgerBox {
    var ledger: any BillingLedger

    init(ledger: any BillingLedger) {
        self.ledger = ledger
    }
}
