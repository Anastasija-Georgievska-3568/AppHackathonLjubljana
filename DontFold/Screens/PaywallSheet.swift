import SwiftUI

/// Modal sheet shown when the user taps "start challenge" with 0 credits.
/// The only blocking surface in the app — everywhere else billing UI is
/// informational.
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LedgerBox.self) private var ledgerBox
    @State private var billing: BillingService?

    private var ledger: any BillingLedger { ledgerBox.ledger }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("out of conversations")
                        .font(DFFont.title(28))
                        .foregroundStyle(Theme.ink)
                        .tracking(-0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 30)

                    Text(subline)
                        .font(DFFont.body(14))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        ForEach(BillingPack.allCases) { pack in
                            PackCard(
                                packSize: pack.size,
                                price: billing?.price(for: pack) ?? pack.fallbackPrice,
                                isBestValue: pack.isBestValue
                            ) {
                                Task { await purchase(pack) }
                            }
                        }
                    }
                    .padding(.top, 6)

                    Button {
                        Task { await billing?.restorePurchases() }
                    } label: {
                        Text("restore purchases")
                            .font(DFFont.body(12))
                            .foregroundStyle(Theme.textSecondary)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                    if let err = billing?.lastError {
                        Text(err)
                            .font(DFFont.body(11))
                            .foregroundStyle(Theme.accent)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("maybe later")
                            .font(DFFont.body(13))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.ink, lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }

            Button { dismiss() } label: {
                Text("×")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .padding(14)
            }
            .buttonStyle(.plain)
        }
        .task {
            if billing == nil {
                billing = BillingService(ledger: ledger)
            }
        }
        .onChange(of: ledger.totalRemaining) { _, newValue in
            if newValue > 0 { dismiss() }
        }
    }

    private var subline: String {
        if let days = ledger.daysUntilFreeRefresh {
            return "you'll have 2 free again in \(days) day\(days == 1 ? "" : "s"), or grab a pack."
        }
        return "grab a pack to keep going."
    }

    private func purchase(_ pack: BillingPack) async {
        guard let billing else { return }
        _ = await billing.purchase(pack)
    }
}
