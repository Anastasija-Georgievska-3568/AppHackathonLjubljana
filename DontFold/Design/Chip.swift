import SwiftUI

/// Hot Girl CEO chip. Two variants: ink (default) — outlined cream pill with
/// ink text — and accent — pink-filled with white text. Used for streak,
/// status row icons, scenario card ↗ button, etc.
struct Chip: View {
    let label: String
    var systemImage: String? = nil
    var tint: Color = Theme.ink
    /// When true, the chip uses a filled accent (pink) background.
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .black))
            }
            Text(label)
                .font(DFFont.micro(9))
                .trackedCaps(1.4)
        }
        .foregroundStyle(filled ? Color.white : Theme.ink)
        .padding(.vertical, 5)
        .padding(.horizontal, 9)
        .background(
            Capsule().fill(filled ? Theme.accent : Theme.bg)
        )
        .overlay(
            Capsule().stroke(Theme.ink, lineWidth: 1.5)
        )
    }
}

/// Small circular chip — used for the ↗ / × glyphs that sit inside cards.
struct GlyphChip: View {
    let glyph: String
    var filled: Bool = true
    var size: CGFloat = 22

    var body: some View {
        Text(glyph)
            .font(.system(size: size * 0.5, weight: .black, design: .rounded))
            .foregroundStyle(filled ? .white : Theme.ink)
            .frame(width: size, height: size)
            .background(
                Circle().fill(filled ? Theme.accent : Theme.bg)
            )
            .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5))
    }
}

