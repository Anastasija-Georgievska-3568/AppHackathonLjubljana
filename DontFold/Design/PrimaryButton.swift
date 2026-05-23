import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
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
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .black))
                }
                Text(title)
                    .font(DFFont.headline(18))
                    .trackedCaps(1.2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 18)
            .padding(.horizontal, 28)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(gradient)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
            }
            .shadow(color: Theme.accent.opacity(0.45), radius: 24, x: 0, y: 12)
            .scaleEffect(pressed ? 0.96 : 1.0)
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

struct GhostButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(DFFont.body(14))
                    .trackedCaps(1.0)
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                Capsule().stroke(Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
