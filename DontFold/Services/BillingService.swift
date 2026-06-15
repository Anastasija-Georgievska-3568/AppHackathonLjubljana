import Foundation
import StoreKit

/// Pack identifiers — these must match App Store Connect product IDs.
enum BillingPack: String, CaseIterable, Identifiable {
    case pack5  = "com.dontfold.pack5"
    case pack10 = "com.dontfold.pack10"
    case pack30 = "com.dontfold.pack30"

    var id: String { rawValue }

    var size: Int {
        switch self {
        case .pack5: return 5
        case .pack10: return 10
        case .pack30: return 30
        }
    }

    /// Fallback price label shown when StoreKit hasn't loaded products yet
    /// or when running on a Simulator without a StoreKit config file.
    var fallbackPrice: String {
        switch self {
        case .pack5: return "$1.99"
        case .pack10: return "$3.49"
        case .pack30: return "$8.99"
        }
    }

    var isBestValue: Bool { self == .pack10 }
}

/// StoreKit 2 integration. Loads the 3 consumable products on init, exposes
/// a `purchase(_:)` that handles the success path including crediting the
/// local ledger. Listens for App Store-initiated transaction updates (e.g.
/// purchases from another device).
@Observable
@MainActor
final class BillingService {
    var products: [Product] = []
    var isPurchasing: Bool = false
    var lastError: String?

    private let ledger: any BillingLedger
    private var updateTask: Task<Void, Never>?

    init(ledger: any BillingLedger) {
        self.ledger = ledger
        updateTask = Task { await self.listenForTransactions() }
        Task { await self.loadProducts() }
    }

    // Note: no `deinit` cancellation — the listener task lives for the app's
    // lifetime since `BillingService` is held as a singleton-like @State on the
    // root. Cancelling from `deinit` would require @MainActor isolation that
    // Swift 6 disallows for deinit.

    func loadProducts() async {
        do {
            let ids = BillingPack.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            self.products = fetched.sorted { lhs, rhs in
                guard let l = BillingPack(rawValue: lhs.id),
                      let r = BillingPack(rawValue: rhs.id) else { return false }
                return l.size < r.size
            }
        } catch {
            #if DEBUG
            print("[Billing] loadProducts: \(error.localizedDescription)")
            #endif
        }
    }

    func price(for pack: BillingPack) -> String {
        if let product = products.first(where: { $0.id == pack.rawValue }) {
            return product.displayPrice
        }
        return pack.fallbackPrice
    }

    func purchase(_ pack: BillingPack) async -> Bool {
        guard let product = products.first(where: { $0.id == pack.rawValue }) else {
            // Try to refresh products and retry once.
            await loadProducts()
            guard let retry = products.first(where: { $0.id == pack.rawValue }) else {
                lastError = "Pack not available."
                return false
            }
            return await purchase(product: retry, pack: pack)
        }
        return await purchase(product: product, pack: pack)
    }

    private func purchase(product: Product, pack: BillingPack) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                return await handle(verification, pack: pack)
            case .userCancelled:
                return false
            case .pending:
                // Family-share / parental approval flow; transaction will arrive
                // via the listener once approved.
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    private func handle(_ verification: VerificationResult<Transaction>, pack: BillingPack) async -> Bool {
        switch verification {
        case .unverified:
            lastError = "Apple couldn't verify this purchase."
            return false
        case .verified(let transaction):
            // Idempotent — ledger de-dupes by txID.
            ledger.recordPurchase(txID: String(transaction.id), pack: pack.size)
            await transaction.finish()
            return true
        }
    }

    /// Restore-purchases. For consumables this only flushes any pending
    /// (unfinished) transactions; user-visible result is usually a no-op.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Background listener for App Store-initiated transactions (e.g. a
    /// purchase made on a different device under the same Apple ID).
    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                if let pack = BillingPack(rawValue: transaction.productID) {
                    ledger.recordPurchase(txID: String(transaction.id), pack: pack.size)
                }
                await transaction.finish()
            }
        }
    }
}
