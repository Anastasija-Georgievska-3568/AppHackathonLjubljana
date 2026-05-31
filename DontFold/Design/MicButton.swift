import SwiftUI

/// Hot Girl CEO mic — small circular pink button with hard ink outline.
/// Sits next to the dashed input pill in the conversation footer. Lower
/// emphasis than the cinematic giant mic in the dark direction.
struct MicButton: View {
    var isListening: Bool
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var pulse: CGFloat = 0

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(Theme.accent.opacity(0.55), lineWidth: 2)
                        .scaleEffect(1.0 + pulse * 0.35)
                        .opacity(1.0 - Double(pulse))
                }
                Circle()
                    .fill(isListening ? Theme.ink : Theme.accent)
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .onAppear { animatePulse() }
        .onChange(of: isListening) { _, _ in animatePulse() }
    }

    private func animatePulse() {
        pulse = 0
        if isListening {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                pulse = 1.0
            }
        }
    }
}
