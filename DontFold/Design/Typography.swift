import SwiftUI

/// "Hot Girl CEO" type system. Personality:
///  - Display: heavy geometric grotesque (Bricolage stand-in: rounded heavy with
///    tight tracking & compressed line height) — for wordmark, hero titles, big numbers.
///  - Body / scribble: casual / hand-written stand-in (use `scribble()` extension).
///  - Eyebrows: tracked uppercase, 9–11pt, mono-flavored.
enum DFFont {
    /// Single source of truth — bump this to scale every text size at once.
    /// 1.0 = wireframe baseline. 1.15 ≈ +15% bigger across the app.
    static let scale: CGFloat = 1.2

    /// Massive wordmark / hero display (e.g. DON'T / FOLD.).
    static func display(_ size: CGFloat = 56) -> Font {
        .system(size: size * scale, weight: .black, design: .rounded)
    }

    /// Section titles, screen titles, headline numbers.
    static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size * scale, weight: .heavy, design: .rounded)
    }

    /// Card titles, "ttl" in the wireframe.
    static func headline(_ size: CGFloat = 15) -> Font {
        .system(size: size * scale, weight: .bold, design: .rounded)
    }

    /// Body / subtitles.
    static func body(_ size: CGFloat = 13) -> Font {
        .system(size: size * scale, weight: .regular, design: .rounded)
    }

    /// Eyebrows / labels / micro chips (uppercase + tracked).
    static func micro(_ size: CGFloat = 9) -> Font {
        .system(size: size * scale, weight: .heavy, design: .monospaced)
    }

    /// Numerical readouts (stats, meters).
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size * scale, weight: .heavy, design: .monospaced)
    }

    /// "Scribbled" hand-style affirmations (e.g. ♡ girlies edition).
    static func scribble(_ size: CGFloat = 13) -> Font {
        .system(size: size * scale, weight: .semibold, design: .serif).italic()
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

/// A rotated handwritten affirmation ("scribble tag"). Stand-in for Caveat /
/// Permanent Marker — italic serif with a small rotation.
struct ScribbleTag: View {
    let text: String
    var rotation: Double = -4
    var color: Color = Theme.accent
    var size: CGFloat = 14

    var body: some View {
        Text(text)
            .font(DFFont.scribble(size))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
    }
}
