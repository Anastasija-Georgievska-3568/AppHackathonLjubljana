import SwiftUI

struct Chip: View {
    let label: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .black))
            }
            Text(label)
                .font(DFFont.micro(11))
                .trackedCaps(1.4)
        }
        .foregroundStyle(tint)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule().fill(tint.opacity(0.14))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.30), lineWidth: 1)
        )
    }
}

struct DifficultyPip: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(i < difficulty.level ? difficulty.tint : Theme.stroke)
                    .frame(width: 6, height: 6)
            }
        }
    }
}
