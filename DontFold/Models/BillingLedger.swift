import Foundation

// MARK: - Event log shapes (also used for v2 backend migration)

struct PurchaseEntry: Codable, Hashable {
    let txID: String
    let pack: Int          // pack size in conversations (5, 10, or 30)
    let date: Date
}

struct ConsumptionEntry: Codable, Hashable {
    let date: Date
    let isFree: Bool
    let scenarioId: String
    let sessionId: String
}

// MARK: - Protocol

/// Abstracted ledger so the rest of the app calls one API regardless of
/// whether storage is local (v1) or server-backed (v2). v2 will add a
/// `RemoteBillingLedger` that talks to the Cloudflare backend; nothing else
/// needs to change.
@MainActor
protocol BillingLedger: AnyObject {
    var totalRemaining: Int { get }
    var freeRemaining: Int { get }
    var paidBalance: Int { get }
    var daysUntilFreeRefresh: Int? { get }   // nil when free credits are already available

    /// Append a purchase (called by `BillingService` after StoreKit verifies).
    func recordPurchase(txID: String, pack: Int)

    /// Deduct a credit per the policy. Free credits first. No-op if user has
    /// no credits (caller should have checked first).
    func consumeCredit(scenarioId: String, sessionId: String)

    /// Wipe everything (account deletion).
    func reset()
}

// MARK: - Local implementation (v1)

@Observable
@MainActor
final class LocalBillingLedger: BillingLedger {
    private let purchasesKey = "billing.purchases"        // Keychain (survives reinstall)
    private let consumptionKey = "billing.consumption"    // UserDefaults

    /// Each free credit is consumed if there are <2 free consumption entries
    /// in the last 30 days. We don't need to store an explicit timestamp list;
    /// the consumption log already contains them.
    private let freeCreditsPerMonth = 2
    private let monthSeconds: TimeInterval = 30 * 24 * 60 * 60

    private(set) var purchases: [PurchaseEntry] = []
    private(set) var consumption: [ConsumptionEntry] = []

    init() {
        loadPurchases()
        loadConsumption()
    }

    // MARK: - BillingLedger conformance

    var totalRemaining: Int { freeRemaining + paidBalance }

    var freeRemaining: Int {
        let now = Date()
        let recent = consumption.filter {
            $0.isFree && now.timeIntervalSince($0.date) <= monthSeconds
        }
        return max(0, freeCreditsPerMonth - recent.count)
    }

    var paidBalance: Int {
        let purchased = purchases.reduce(0) { $0 + $1.pack }
        let consumed = consumption.filter { !$0.isFree }.count
        return max(0, purchased - consumed)
    }

    var daysUntilFreeRefresh: Int? {
        guard freeRemaining == 0 else { return nil }
        // Oldest of the last 2 free consumption entries dictates the wait.
        let now = Date()
        let recent = consumption
            .filter { $0.isFree && now.timeIntervalSince($0.date) <= monthSeconds }
            .sorted { $0.date < $1.date }
        guard let oldest = recent.first else { return nil }
        let refreshDate = oldest.date.addingTimeInterval(monthSeconds)
        let days = Int(refreshDate.timeIntervalSince(now) / 86_400)
        return max(1, days)
    }

    func recordPurchase(txID: String, pack: Int) {
        // De-dupe by txID (StoreKit transaction updates can re-deliver).
        guard !purchases.contains(where: { $0.txID == txID }) else { return }
        purchases.append(PurchaseEntry(txID: txID, pack: pack, date: Date()))
        savePurchases()
    }

    func consumeCredit(scenarioId: String, sessionId: String) {
        let useFree = freeRemaining > 0
        consumption.append(
            ConsumptionEntry(
                date: Date(),
                isFree: useFree,
                scenarioId: scenarioId,
                sessionId: sessionId
            )
        )
        saveConsumption()
    }

    func reset() {
        purchases = []
        consumption = []
        KeychainStorage.delete(forKey: purchasesKey)
        UserDefaults.standard.removeObject(forKey: consumptionKey)
    }

    // MARK: - Persistence

    private func loadPurchases() {
        guard let raw = KeychainStorage.get(forKey: purchasesKey),
              let data = raw.data(using: .utf8) else { return }
        purchases = (try? JSONDecoder.iso.decode([PurchaseEntry].self, from: data)) ?? []
    }

    private func savePurchases() {
        let data = (try? JSONEncoder.iso.encode(purchases)) ?? Data()
        let raw = String(data: data, encoding: .utf8) ?? "[]"
        KeychainStorage.set(raw, forKey: purchasesKey)
    }

    private func loadConsumption() {
        guard let data = UserDefaults.standard.data(forKey: consumptionKey) else { return }
        consumption = (try? JSONDecoder.iso.decode([ConsumptionEntry].self, from: data)) ?? []
    }

    private func saveConsumption() {
        let data = (try? JSONEncoder.iso.encode(consumption)) ?? Data()
        UserDefaults.standard.set(data, forKey: consumptionKey)
    }
}

// MARK: - ISO 8601 codec helpers

extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
