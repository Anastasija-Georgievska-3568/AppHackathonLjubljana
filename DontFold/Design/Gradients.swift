import SwiftUI

/// Gradients are kept around as flat-color "gradients" so existing call sites
/// still compile. In the Hot Girl CEO direction we lean on solid hot pink and
/// ink rather than soft transitions.
enum DFGradient {
    static let hero = LinearGradient(
        colors: [Theme.accent, Theme.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cool = LinearGradient(
        colors: [Theme.accent2, Theme.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let danger = LinearGradient(
        colors: [Theme.accent, Theme.accent],
        startPoint: .top,
        endPoint: .bottom
    )

    static let success = LinearGradient(
        colors: [Theme.accent, Theme.accent],
        startPoint: .top,
        endPoint: .bottom
    )

    static let backgroundVeil = LinearGradient(
        colors: [Theme.bg, Theme.bg],
        startPoint: .top,
        endPoint: .bottom
    )

    static func pressureFill(level: Double) -> LinearGradient {
        LinearGradient(
            colors: [Theme.accent, Theme.accent],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// In the Hot Girl CEO direction, the "animated aurora" softens to a flat cream
/// background — we keep the type around so existing call sites compile and the
/// surface stays consistent without an aurora glow.
struct AnimatedAuroraBackground: View {
    var intensity: Double = 1.0

    var body: some View {
        Theme.bg.ignoresSafeArea()
    }
}
