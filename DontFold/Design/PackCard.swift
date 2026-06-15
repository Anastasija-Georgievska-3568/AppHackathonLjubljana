import SwiftUI

/// A single pack option in the drawer / paywall. Pack size on the left,
/// localized price on the right, optional "best value" tag.
struct PackCard: View {
    let packSize: Int
    let price: String
    var isBestValue: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text("+\(packSize) convos")
                    .font(DFFont.headline(14))
                    .foregroundStyle(Theme.ink)
                if isBestValue {
                    Text("BEST VALUE")
                        .font(DFFont.micro(8))
                        .foregroundStyle(Theme.accent)
                        .tracking(0.8)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Theme.accent, lineWidth: 1)
                        )
                }
                Spacer()
                Text(price)
                    .font(DFFont.mono(14))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.ink, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}
