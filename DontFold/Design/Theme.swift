import SwiftUI

/// Hot Girl CEO palette: cream surface, ink ("near-black") text & borders,
/// hot-pink accent, soft-pink highlight fills. Hard outlines over shadows.
enum Theme {
    static let bg          = Color(hex: 0xFFFDF7) // cream
    static let bgElevated  = Color(hex: 0xFFE6F0) // soft pink (highlight card fill)
    static let surface     = Color(hex: 0xFFFDF7)
    static let surfaceHi   = Color(hex: 0xFFE6F0)

    static let ink         = Color(hex: 0x0D0D0D)
    static let accent      = Color(hex: 0xFF2D87) // hot pink
    static let accent2     = Color(hex: 0xFF7AB6) // softer pink
    static let accent3     = Color(hex: 0xFFD6E6) // dashed-bubble pink
    static let success     = Color(hex: 0xFF2D87)
    static let warning     = Color(hex: 0xC41E3A)
    static let danger      = Color(hex: 0xFF2D87)

    static let textPrimary   = Color(hex: 0x0D0D0D)
    static let textSecondary = Color(hex: 0x33312D)
    static let textMuted     = Color(hex: 0x33312D).opacity(0.55)
    static let stroke        = Color(hex: 0x0D0D0D).opacity(0.85)
    static let strokeHi      = Color(hex: 0x0D0D0D)

    static let bubbleGray    = Color(hex: 0xF0F0F0)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
