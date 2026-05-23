import SwiftUI

enum DFGradient {
    static let hero = LinearGradient(
        colors: [Theme.accent, Theme.accent2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cool = LinearGradient(
        colors: [Theme.accent3, Theme.accent2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let danger = LinearGradient(
        colors: [Color(hex: 0xFF5A36), Theme.accent],
        startPoint: .top,
        endPoint: .bottom
    )

    static let success = LinearGradient(
        colors: [Theme.success, Theme.accent3],
        startPoint: .top,
        endPoint: .bottom
    )

    static let backgroundVeil = LinearGradient(
        colors: [
            Theme.bg,
            Color(hex: 0x16101F),
            Theme.bg
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func pressureFill(level: Double) -> LinearGradient {
        let pinned = max(0, min(1, level))
        if pinned > 0.66 {
            return danger
        } else if pinned > 0.33 {
            return LinearGradient(
                colors: [Theme.warning, Theme.accent],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Theme.accent2, Theme.accent3],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct AnimatedAuroraBackground: View {
    @State private var t: CGFloat = 0
    var intensity: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Theme.bg
                blob(color: Theme.accent.opacity(0.55 * intensity),
                     x: 0.25 + 0.18 * sin(phase * 0.18),
                     y: 0.18 + 0.12 * cos(phase * 0.22),
                     scale: 1.2)
                blob(color: Theme.accent2.opacity(0.55 * intensity),
                     x: 0.75 + 0.20 * sin(phase * 0.13 + 1.2),
                     y: 0.30 + 0.14 * cos(phase * 0.17 + 0.6),
                     scale: 1.4)
                blob(color: Theme.accent3.opacity(0.38 * intensity),
                     x: 0.50 + 0.22 * sin(phase * 0.09 + 2.4),
                     y: 0.78 + 0.10 * cos(phase * 0.12 + 1.8),
                     scale: 1.6)
                Color.black.opacity(0.25)
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func blob(color: Color, x: Double, y: Double, scale: CGFloat) -> some View {
        GeometryReader { proxy in
            Circle()
                .fill(color)
                .frame(width: proxy.size.width * 0.9, height: proxy.size.width * 0.9)
                .scaleEffect(scale)
                .blur(radius: 90)
                .position(x: proxy.size.width * x, y: proxy.size.height * y)
        }
    }
}
