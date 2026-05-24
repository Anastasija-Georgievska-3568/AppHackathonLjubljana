import SwiftUI
import UIKit

struct ShareCardScreen: View {
    let result: SessionResult
    @Environment(Router.self) private var router
    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                ShareCardView(result: result, isCompact: false)
                    .aspectRatio(9.0/16.0, contentMode: .fit)
                    .padding(.horizontal, 16)
                Spacer(minLength: 0)
                actions
                    .padding(.top, 8)
            }
            .padding(.top, 6)
            .padding(.bottom, 22)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingShareSheet) {
            if let renderedImage {
                ActivityView(items: [renderedImage, result.oneLinerToShare])
            }
        }
    }

    private var header: some View {
        HStack {
            Button { router.pop() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.10)))
            }
            Spacer()
            Text("YOUR DROP")
                .font(DFFont.micro(11))
                .foregroundStyle(Theme.textSecondary)
                .trackedCaps(1.8)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 22)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            GhostButton(title: "Save Image", systemImage: "square.and.arrow.down") {
                saveImage()
            }
            PrimaryButton(title: "Share", systemImage: "square.and.arrow.up") {
                renderImage()
                showingShareSheet = true
            }
        }
        .padding(.horizontal, 22)
    }

    @MainActor
    private func renderImage() {
        let renderer = ImageRenderer(
            content: ShareCardView(result: result, isCompact: false)
                .frame(width: 1080, height: 1920)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 1
        renderer.isOpaque = true
        renderedImage = renderer.uiImage
    }

    @MainActor
    private func saveImage() {
        renderImage()
        guard let img = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ShareCardView: View {
    let result: SessionResult
    var isCompact: Bool = false

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(alignment: .leading, spacing: isCompact ? 16 : 26) {
                topRow
                Spacer(minLength: 0)
                verdictBlock
                Spacer(minLength: 0)
                statRow
                footer
            }
            .padding(isCompact ? 22 : 36)
        }
        .aspectRatio(9.0/16.0, contentMode: .fit)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0B0617), Color(hex: 0x1A0C2C), Color(hex: 0x07060B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Glow blobs
            Circle()
                .fill(Theme.accent.opacity(0.65))
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: -120, y: -200)
            Circle()
                .fill(Theme.accent2.opacity(0.55))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: 140, y: 220)
            // Noise grain (subtle)
            Rectangle()
                .fill(Color.white.opacity(0.015))
        }
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 24 : 0, style: .continuous))
    }

    private var topRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DON'T")
                    .font(.system(size: isCompact ? 14 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("FOLD.")
                    .font(.system(size: isCompact ? 14 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(DFGradient.hero)
            }
            Spacer()
            Text(result.scenarioTitle.uppercased())
                .font(.system(size: isCompact ? 9 : 13, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.6)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: isCompact ? 140 : 280, alignment: .trailing)
        }
    }

    private var shareTitleSize: CGFloat {
        let len = result.verdictTitle.count
        if isCompact {
            switch len {
            case 0...14: return 38
            case 15...22: return 32
            case 23...32: return 26
            default: return 22
            }
        } else {
            switch len {
            case 0...14: return 86
            case 15...22: return 72
            case 23...32: return 58
            default: return 46
            }
        }
    }

    private var verdictBlock: some View {
        VStack(alignment: .leading, spacing: isCompact ? 10 : 18) {
            Text("VERDICT")
                .font(.system(size: isCompact ? 9 : 13, weight: .black, design: .rounded))
                .foregroundStyle(Theme.accent)
                .tracking(1.8)
            Text(result.verdictTitle.uppercased())
                .font(.system(size: shareTitleSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.5)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
            Text("\u{201C}\(result.oneLinerToShare)\u{201D}")
                .font(.system(size: isCompact ? 13 : 22, weight: .semibold, design: .rounded))
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statRow: some View {
        HStack(spacing: isCompact ? 8 : 14) {
            mini("PRESSURE", "\(Int(result.finalPressure * 100))", Theme.danger)
            mini("CONFIDENCE", "\(Int(result.finalConfidence * 100))", Theme.success)
            if let first = result.stats.first {
                mini(first.label, first.value, Theme.accent2)
            }
        }
    }

    private func mini(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: isCompact ? 8 : 11, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .tracking(1.4)
            Text(value)
                .font(.system(size: isCompact ? 22 : 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(isCompact ? 10 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 18)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 18)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack {
            Text("dontfold.app")
                .font(.system(size: isCompact ? 10 : 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.4)
            Spacer()
            Text(result.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: isCompact ? 10 : 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.2)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
