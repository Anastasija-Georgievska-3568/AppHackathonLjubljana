import SwiftUI

/// Segmented 5-pip meter — Hot Girl CEO direction. Each pip is a small
/// ink-outlined rectangle that fills with `tint` when "on". `PressureMeter`
/// uses pink; `ConfidenceMeter` uses ink.
private struct SegmentedBar: View {
    var level: Double           // 0…1
    var tint: Color
    var segments: Int = 5

    var filled: Int {
        let clamped = max(0, min(1, level))
        return Int(round(clamped * Double(segments)))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i < filled ? tint : Theme.bg)
                    .frame(height: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Theme.ink, lineWidth: 1.2)
                    )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: filled)
    }
}

struct PressureMeter: View {
    /// 0.0 … 1.0
    var level: Double
    var label: String = "Pressure"

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(DFFont.micro(9))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.4)
            SegmentedBar(level: level, tint: Theme.accent)
        }
    }
}

struct ConfidenceMeter: View {
    /// 0.0 … 1.0
    var level: Double
    var label: String = "Confidence"

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(DFFont.micro(9))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.4)
            SegmentedBar(level: level, tint: Theme.ink)
        }
    }
}
