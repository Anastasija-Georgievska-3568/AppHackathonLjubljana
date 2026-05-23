import SwiftUI

enum DFFont {
    /// Massive marquee headlines — for hero moments only.
    static func display(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    /// Section titles, screen titles.
    static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    /// Card labels, smaller titles.
    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Body copy.
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    /// Tag / chip / micro labels — uppercase, tracked.
    static func micro(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    /// Numerical / meter readout.
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }
}

struct TrackedCaps: ViewModifier {
    var tracking: CGFloat = 1.6
    func body(content: Content) -> some View {
        content
            .textCase(.uppercase)
            .tracking(tracking)
    }
}

extension View {
    func trackedCaps(_ tracking: CGFloat = 1.6) -> some View {
        modifier(TrackedCaps(tracking: tracking))
    }
}
