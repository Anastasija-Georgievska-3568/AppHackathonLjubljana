import SwiftUI

/// Hot Girl CEO "sticker card": cream fill, hard ink outline (1.5–2 px),
/// 12 px radius. Set `highlighted: true` to use the soft-pink highlight fill.
/// `offsetShadow: true` gives the flat 3×3 ink shadow for sticker accent moments.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 12
    /// Kept for compatibility with older call sites; ignored — the new card
    /// always uses ink outlines, with optional pink accent via `highlighted`.
    var strokeColor: Color = Theme.stroke
    var highlighted: Bool = false
    var offsetShadow: Bool = false
    var borderWidth: CGFloat = 1.5
    @ViewBuilder var content: () -> Content

    var fill: Color {
        highlighted ? Theme.bgElevated : Theme.bg
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Apply the sticker shadow to the card *shape* only — not the
                // whole view — otherwise the offset shadow is cast on every
                // glyph and the text reads as doubled.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .shadow(
                        color: offsetShadow ? Theme.ink.opacity(0.9) : .clear,
                        radius: 0,
                        x: offsetShadow ? 3 : 0,
                        y: offsetShadow ? 3 : 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: borderWidth)
            )
    }
}
