import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x07060B)
    static let bgElevated = Color(hex: 0x121119)
    static let surface = Color(hex: 0x191824)
    static let surfaceHi = Color(hex: 0x22202F)

    static let accent = Color(hex: 0xFF3B6B)      // hot pink
    static let accent2 = Color(hex: 0xA66CFF)     // violet
    static let accent3 = Color(hex: 0x4DE3FF)     // electric cyan
    static let success = Color(hex: 0x5BFFA8)
    static let warning = Color(hex: 0xFFC857)
    static let danger = Color(hex: 0xFF3551)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textMuted = Color.white.opacity(0.42)
    static let stroke = Color.white.opacity(0.10)
    static let strokeHi = Color.white.opacity(0.18)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
