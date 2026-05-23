import SwiftUI

/// Reveals text character-by-character with a soft fade. Cinematic AI dialogue feel.
struct TypeOnText: View {
    let text: String
    var charactersPerSecond: Double = 42
    var font: Font = DFFont.headline(22)
    var color: Color = Theme.textPrimary

    @State private var revealed: Int = 0

    var body: some View {
        Text(displayed)
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear { animate() }
            .onChange(of: text) { _, _ in
                revealed = 0
                animate()
            }
    }

    private var displayed: String {
        guard revealed < text.count else { return text }
        let idx = text.index(text.startIndex, offsetBy: revealed)
        return String(text[..<idx])
    }

    private func animate() {
        let total = text.count
        guard total > 0 else { return }
        let interval = 1.0 / max(8.0, charactersPerSecond)
        Task { @MainActor in
            for i in 1...total {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                withAnimation(.easeOut(duration: 0.05)) {
                    revealed = i
                }
            }
        }
    }
}
