import SwiftUI

struct MicButton: View {
    var isListening: Bool
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var ringPhase: CGFloat = 0

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        } label: {
            ZStack {
                if isListening {
                    Circle()
                        .stroke(Theme.accent.opacity(0.6), lineWidth: 2)
                        .scaleEffect(1.0 + ringPhase * 0.35)
                        .opacity(1.0 - Double(ringPhase))
                    Circle()
                        .stroke(Theme.accent2.opacity(0.5), lineWidth: 2)
                        .scaleEffect(1.0 + ringPhase * 0.55)
                        .opacity(1.0 - Double(ringPhase))
                }
                Circle()
                    .fill(isListening ? DFGradient.danger : DFGradient.hero)
                    .shadow(color: (isListening ? Theme.danger : Theme.accent).opacity(0.55), radius: 24, y: 8)
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 88, height: 88)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .onAppear { animateRings() }
        .onChange(of: isListening) { _, _ in animateRings() }
    }

    private func animateRings() {
        ringPhase = 0
        if isListening {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                ringPhase = 1.0
            }
        }
    }
}
