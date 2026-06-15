import SwiftUI

/// Left drawer with Profile / Settings / Billing sections. Lives in a
/// `ZStack` overlay in `RootView`. Slide-in from the left, ~85% width.
struct SideMenuView: View {
    @Environment(MenuState.self) private var menu
    @Environment(UserSession.self) private var session
    @Environment(LedgerBox.self) private var ledgerBox
    @Environment(SessionHistoryStore.self) private var history
    @Environment(Router.self) private var router

    @AppStorage("settings.voice") private var voiceEnabled: Bool = true
    @AppStorage("settings.haptics") private var hapticsEnabled: Bool = true

    @State private var showDeleteConfirm = false
    @State private var billing: BillingService?

    private var ledger: any BillingLedger { ledgerBox.ledger }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.bg

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    profile
                    divider
                    settings
                    divider
                    billingSection
                    divider
                    versionLine
                    actions
                }
                .padding(.horizontal, 18)
                .padding(.top, 52)
                .padding(.bottom, 32)
            }

            closeButton
                .padding(.top, 14)
                .padding(.trailing, 14)
        }
        .frame(maxHeight: .infinity)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Theme.ink)
                .frame(width: 1.5)
        }
        .task {
            if billing == nil {
                billing = BillingService(ledger: ledger)
            }
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes your account and clears your conversation history. Paid credits are not refundable.")
        }
    }

    // MARK: - Profile

    private var profile: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.bg)
                Circle()
                    .stroke(Theme.ink, lineWidth: 1.5)
                Text(session.initials)
                    .font(DFFont.headline(13))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName ?? "you")
                    .font(DFFont.headline(15))
                    .foregroundStyle(Theme.ink)
                if let email = session.email, !email.isEmpty {
                    Text(email)
                        .font(DFFont.body(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }

    // MARK: - Settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .tracking(1.0)

            toggleRow(label: "voice playback", binding: $voiceEnabled)
            toggleRow(label: "haptics",        binding: $hapticsEnabled)
        }
    }

    private func toggleRow(label: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(DFFont.body(14))
                .foregroundStyle(Theme.ink)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Theme.accent)
        }
    }

    // MARK: - Billing

    private var billingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BILLING")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .tracking(1.0)

            Text("plan · free")
                .font(DFFont.body(13))
                .foregroundStyle(Theme.ink)

            Text(creditsLine)
                .font(DFFont.body(12))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 8) {
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

            Button {
                Task { await billing?.restorePurchases() }
            } label: {
                Text("restore purchases")
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            if let err = billing?.lastError {
                Text(err)
                    .font(DFFont.body(11))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 4)
            }
        }
    }

    private var creditsLine: String {
        let free = ledger.freeRemaining
        let paid = ledger.paidBalance
        return "credits · \(free) free · \(paid) paid"
    }

    private func purchase(_ pack: BillingPack) async {
        guard let billing else { return }
        _ = await billing.purchase(pack)
    }

    // MARK: - Bottom

    private var versionLine: some View {
        Text("v\(Bundle.main.shortVersion) · build \(Bundle.main.buildNumber)")
            .font(DFFont.micro(10))
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.8)
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                signOut()
            } label: {
                Text("sign out")
                    .font(DFFont.headline(13))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.ink, lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)

            Button {
                showDeleteConfirm = true
            } label: {
                Text("delete account")
                    .font(DFFont.body(12))
                    .foregroundStyle(Theme.textSecondary)
                    .underline()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Actions

    private var closeButton: some View {
        Button { menu.close() } label: {
            Text("×")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(Theme.ink)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.ink.opacity(0.2))
            .frame(height: 1)
    }

    private func signOut() {
        session.signOut()
        menu.close()
        router.popToRoot()
    }

    private func deleteAccount() {
        // v1: local-only deletion. Server-side delete + Apple revocation = v1.1.
        ledger.reset()
        history.reset()
        session.signOut()
        menu.close()
        router.popToRoot()
    }
}

// MARK: - Bundle helpers

private extension Bundle {
    var shortVersion: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0" }
    var buildNumber: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }
}
