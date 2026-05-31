import SwiftUI
import UIKit

/// Share screen — the result card is the shareable artifact. Designed to
/// export to a vertical 9:16 image (Instagram-Story / TikTok-overlay).
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.ink, lineWidth: 1.5)
                            .padding(.horizontal, 16)
                    )
                Spacer(minLength: 0)
                actions
                    .padding(.top, 12)
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
                GlyphChip(glyph: "←", filled: false, size: 30)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("your drop")
                .font(DFFont.micro(10))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Spacer()
            Color.clear.frame(width: 30, height: 30)
        }
        .padding(.horizontal, 16)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            GhostButton(title: "Save Image", systemImage: "square.and.arrow.down") {
                saveImage()
            }
            PrimaryButton(title: "Share", systemImage: "square.and.arrow.up") {
                renderImage()
                showingShareSheet = true
            }
        }
        .padding(.horizontal, 16)
    }

    @MainActor
    private func renderImage() {
        let renderer = ImageRenderer(
            content: ShareCardView(result: result, isCompact: false)
                .frame(width: 1080, height: 1920)
                .environment(\.colorScheme, .light)
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

/// 9:16 share artifact — Hot Girl CEO. Cream background with ink outline,
/// big DON'T / FOLD. wordmark, pink VERDICT card, two stat cards, footer.
struct ShareCardView: View {
    let result: SessionResult
    var isCompact: Bool = false

    var body: some View {
        ZStack {
            // Background
            Theme.bg
            VStack(spacing: 0) {
                topRow
                    .padding(.top, isCompact ? 18 : 50)
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
                verdictBlock
                    .padding(.top, isCompact ? 12 : 28)
                Spacer(minLength: 0)
                statRow
                    .padding(.top, isCompact ? 12 : 28)
                Spacer(minLength: 0)
                footer
                    .padding(.bottom, isCompact ? 18 : 50)
            }
            .padding(.horizontal, isCompact ? 18 : 50)
        }
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 14 : 0, style: .continuous))
        .aspectRatio(9.0/16.0, contentMode: .fit)
    }

    private var topRow: some View {
        HStack {
            Text("your drop")
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
            Spacer()
            Text(dateLabel)
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
        }
    }

    private var hero: some View {
        VStack(spacing: -(isCompact ? 8 : 18)) {
            Text("DON'T")
                .font(DFFont.display(isCompact ? 54 : 130))
                .foregroundStyle(Theme.ink)
                .tracking(-1.0)
            Text("FOLD.")
                .font(DFFont.display(isCompact ? 54 : 130))
                .foregroundStyle(Theme.accent)
                .tracking(-1.0)
        }
        .frame(maxWidth: .infinity)
    }

    private var verdictBlock: some View {
        VStack(spacing: 4) {
            Text("verdict")
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Text(result.verdictTitle.uppercased())
                .font(DFFont.title(isCompact ? verdictSize.compact : verdictSize.full))
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)
                .tracking(-0.5)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.6)
        }
        .padding(isCompact ? 12 : 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 24, style: .continuous)
                .fill(Theme.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 24, style: .continuous)
                .stroke(Theme.ink, lineWidth: isCompact ? 1.5 : 4)
        )
    }

    private var verdictSize: (compact: CGFloat, full: CGFloat) {
        let len = result.verdictTitle.count
        switch len {
        case 0...14: return (compact: 24, full: 68)
        case 15...22: return (compact: 20, full: 58)
        case 23...32: return (compact: 17, full: 46)
        default: return (compact: 14, full: 38)
        }
    }

    private var statRow: some View {
        HStack(spacing: isCompact ? 8 : 18) {
            statCard(label: "pressure",
                     value: Int(result.finalPressure * 100),
                     highlighted: false)
            statCard(label: "confidence",
                     value: Int(result.finalConfidence * 100),
                     highlighted: true)
        }
    }

    private func statCard(label: String, value: Int, highlighted: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Text("\(value)")
                .font(DFFont.title(isCompact ? 30 : 90))
                .foregroundStyle(highlighted ? Theme.accent : Theme.ink)
        }
        .padding(isCompact ? 10 : 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 10 : 22, style: .continuous)
                .fill(highlighted ? Theme.bgElevated : Theme.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 10 : 22, style: .continuous)
                .stroke(Theme.ink, lineWidth: isCompact ? 1.5 : 4)
        )
    }

    private var footer: some View {
        HStack {
            Text("dontfold.app")
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.ink)
                .trackedCaps(1.6)
            Spacer()
            Text(result.scenarioTitle.lowercased())
                .font(DFFont.micro(isCompact ? 9 : 16))
                .foregroundStyle(Theme.accent)
                .trackedCaps(1.6)
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: result.date).lowercased()
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
