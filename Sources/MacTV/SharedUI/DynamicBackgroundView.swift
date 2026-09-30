import AVKit
import SwiftUI

struct DynamicBackgroundView: View {
    let settings: AppearanceSettings
    let url: URL?

    var body: some View {
        ZStack {
            switch settings.backgroundKind {
            case .builtIn:
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.08, blue: 0.14), Color(red: 0.15, green: 0.12, blue: 0.24), Color.black],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                RadialGradient(colors: [.blue.opacity(0.42), .clear], center: .topTrailing, startRadius: 30, endRadius: 650)
            case .image:
                if let url, let image = NSImage(contentsOf: url) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else { fallback }
            case .video:
                if let url, settings.motionEnabled {
                    LoopingVideoView(url: url)
                } else if let url, let image = videoPoster(url: url) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else { fallback }
            }
        }
        .blur(radius: settings.backgroundBlur)
        .overlay(Color.black.opacity(settings.backgroundDim))
        .ignoresSafeArea()
    }

    private var fallback: some View {
        LinearGradient(colors: [.indigo.opacity(0.7), .black], startPoint: .topTrailing, endPoint: .bottomLeading)
    }

    private func videoPoster(url: URL) -> NSImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        guard let image = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
        return NSImage(cgImage: image, size: .zero)
    }
}

private struct LoopingVideoView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PlayerContainerView {
        PlayerContainerView(url: url)
    }

    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.setURL(url)
    }
}

private final class PlayerContainerView: NSView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    init(url: URL) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspectFill
        setURL(url)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    func setURL(_ url: URL) {
        guard currentURL != url else { return }
        currentURL = url
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        queuePlayer = player
        looper = AVPlayerLooper(player: player, templateItem: item)
        playerLayer.player = player
        player.play()
    }
}
