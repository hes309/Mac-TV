import SwiftUI
import WebKit

@MainActor
final class MusicPlaybackController: ObservableObject {
    static let shared = MusicPlaybackController()

    @Published private(set) var serviceName: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var isLiked = false

    private var cachedWebViews: [UUID: WKWebView] = [:]
    private weak var activeWebView: WKWebView?

    private init() {}

    func webView(for shortcut: ShortcutItem, configuration: WKWebViewConfiguration) -> WKWebView {
        if let existing = cachedWebViews[shortcut.id] {
            existing.removeFromSuperview()
            if shortcut.isMusicService {
                activeWebView = existing
                serviceName = shortcut.title
            }
            return existing
        }
        let webView = WKWebView(frame: .zero, configuration: configuration)
        cachedWebViews[shortcut.id] = webView
        if shortcut.isMusicService {
            activeWebView = webView
            serviceName = shortcut.title
        }
        return webView
    }

    func markActive(_ shortcut: ShortcutItem, webView: WKWebView) {
        guard shortcut.isMusicService else { return }
        activeWebView = webView
        serviceName = shortcut.title
    }

    func previous() { run(.previous) }
    func next() { run(.next) }

    func togglePlayPause() {
        run(.toggle)
        isPlaying.toggle()
    }

    func toggleLike() {
        run(.like)
        isLiked.toggle()
    }

    func pauseForNonMusicLaunch() {
        guard activeWebView != nil else { return }
        run(.pauseOnly)
        isPlaying = false
    }

    private func run(_ command: Command) {
        guard let webView = activeWebView else { return }
        webView.evaluateJavaScript(command.script)
    }

    private enum Command {
        case previous, next, toggle, pauseOnly, like

        var selectors: [String] {
            switch self {
            case .previous: [".prv", ".btn_prev", ".player__btn--prev", "[aria-label*='上一']", "[title*='上一']"]
            case .next: [".nxt", ".btn_next", ".player__btn--next", "[aria-label*='下一']", "[title*='下一']"]
            case .toggle: [".ply", ".btn_big_play", ".player__btn--play", "[aria-label*='播放']", "[aria-label*='暂停']", "[title*='播放']", "[title*='暂停']"]
            case .pauseOnly: [".ply.pas", ".btn_big_play--pause", ".player__btn--pause", "[aria-label*='暂停']", "[title*='暂停']"]
            case .like: [".icn-add", ".btn_fav", ".player__btn--like", "[aria-label*='收藏']", "[title*='收藏']"]
            }
        }

        var script: String {
            let encoded = selectors.map { "'\($0)'" }.joined(separator: ",")
            return """
            (() => {
              const selectors = [\(encoded)];
              const roots = [document];
              for (const frame of document.querySelectorAll('iframe')) {
                try { if (frame.contentDocument) roots.push(frame.contentDocument); } catch (_) {}
              }
              for (const root of roots) {
                for (const selector of selectors) {
                  const element = root.querySelector(selector);
                  if (element) { element.click(); return true; }
                }
              }
              return false;
            })();
            """
        }
    }
}
