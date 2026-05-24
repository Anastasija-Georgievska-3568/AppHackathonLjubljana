import SwiftUI

struct PressureMeter: View {
    /// 0.0 ... 1.0
    var level: Double
    var label: String = "Pressure"

    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label)
                    .font(DFFont.micro(10))
                    .foregroundStyle(level > 0.66 ? Theme.danger : Theme.textSecondary)
                    .trackedCaps(1.4)
                Spacer()
                Text("\(Int(level * 100))")
                    .font(DFFont.mono(13))
                    .foregroundStyle(level > 0.66 ? Theme.danger : .white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: level)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(DFGradient.pressureFill(level: level))
                        .frame(width: max(10, proxy.size.width * level))
                        .shadow(color: Theme.accent.opacity(level > 0.5 ? 0.6 : 0), radius: 14, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)
                    if level > 0.75 {
                        Capsule()
                            .stroke(Theme.danger.opacity(pulse ? 0.0 : 0.9), lineWidth: 1.5)
                            .frame(width: max(10, proxy.size.width * level))
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                    }
                }
            }
            .frame(height: 8)
            .onAppear { pulse = true }
        }
    }
}

struct ConfidenceMeter: View {
    /// 0.0 ... 1.0
    var level: Double
    var label: String = "Confidence"

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label)
                    .font(DFFont.micro(10))
                    .foregroundStyle(level > 0.5 ? Theme.success : Theme.textSecondary)
                    .trackedCaps(1.4)
                Spacer()
                Text("\(Int(level * 100))")
                    .font(DFFont.mono(13))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: level)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(DFGradient.success)
                        .frame(width: max(10, proxy.size.width * level))
                        .shadow(color: Theme.success.opacity(level > 0.4 ? 0.45 : 0), radius: 14, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)
                }
            }
            .frame(height: 8)
        }
    }
}
