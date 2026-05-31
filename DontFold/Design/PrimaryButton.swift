import SwiftUI

/// Hot Girl CEO primary CTA. Flat pink card with ink outline. Reads as a
/// "card you tap" — matches the wireframe's full-width footer CTA.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    /// Kept for API compatibility; ignored — Hot Girl CEO uses solid hot pink.
    var gradient: LinearGradient = DFGradient.hero
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .black))
                }
                Text(title)
                    .font(DFFont.headline(15))
                    .trackedCaps(1.2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.ink, lineWidth: 1.5)
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pressed = false }
                }
        )
    }
}

/// Secondary action — outlined cream pill with ink text. Lower-emphasis CTA.
struct GhostButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(DFFont.headline(13))
                    .trackedCaps(1.2)
            }
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 11)
            .padding(.horizontal, 18)
            .background(
                Capsule().fill(Theme.bg)
            )
            .overlay(
                Capsule().stroke(Theme.ink, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
