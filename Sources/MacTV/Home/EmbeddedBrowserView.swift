import SwiftUI
import WebKit

struct EmbeddedBrowserView: View {
    let shortcut: ShortcutItem
    let url: URL
    let close: () -> Void
    @State private var addressText: String
    @State private var requestedURL: URL
    @State private var requestVersion = 0
    @StateObject private var controls: BrowserNavigationControls

    init(shortcut: ShortcutItem, url: URL, close: @escaping () -> Void) {
        self.shortcut = shortcut
        self.url = url
        self.close = close
        _addressText = State(initialValue: url.absoluteString)
        _requestedURL = State(initialValue: url)
        _controls = StateObject(wrappedValue: BrowserNavigationControls())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                BrandLogoView(shortcut: shortcut, size: 28)
                Text(shortcut.title).font(.headline)
                HStack(spacing: 7) {
                    toolbarButton("chevron.left", help: "后退", enabled: controls.hasWebView) { controls.goBack() }
                    toolbarButton("chevron.right", help: "前进", enabled: controls.hasWebView) { controls.goForward() }
                    toolbarButton("minus", help: "最小化", enabled: true) { close() }
                }
                .padding(.leading, 6)
                Spacer()
                if shortcut.isBrowserShortcut {
                    TextField("输入网址或搜索内容", text: $addressText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 13)
                        .frame(maxWidth: 520)
                        .frame(height: 32)
                        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 9))
                        .onSubmit {
                            requestedURL = resolvedAddress
                            addressText = requestedURL.absoluteString
                            requestVersion += 1
                        }
                } else {
                    Text(url.host() ?? "").font(.caption).foregroundStyle(.secondary)
                }
                Button(action: close) {
                    Label("返回首页", systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 5)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(.ultraThinMaterial)

            WebContainer(
                shortcut: shortcut,
                url: shortcut.isBrowserShortcut ? requestedURL : url,
                requestVersion: requestVersion,
                controls: controls
            )
                .id(shortcut.id)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func toolbarButton(_ symbol: String, help: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 30, height: 28)
                .background(.white.opacity(enabled ? 0.1 : 0.045), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .disabled(!enabled)
        .help(help)
        .accessibilityLabel(help)
    }

    private var resolvedAddress: URL {
        let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let direct = URL(string: trimmed), direct.scheme != nil { return direct }
        if !trimmed.contains(" "), let direct = URL(string: "https://\(trimmed)") { return direct }
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        return components.url ?? url
    }
}

@MainActor
private final class BrowserNavigationControls: ObservableObject {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var hasWebView = false
    private weak var webView: WKWebView?
    private var backObservation: NSKeyValueObservation?
    private var forwardObservation: NSKeyValueObservation?

    func attach(_ webView: WKWebView) {
        backObservation = nil
        forwardObservation = nil
        self.webView = webView
        hasWebView = true
        backObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in self?.canGoBack = webView.canGoBack }
        }
        forwardObservation = webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in self?.canGoForward = webView.canGoForward }
        }
        update()
    }

    func update() {
        canGoBack = webView?.canGoBack == true
        canGoForward = webView?.canGoForward == true
    }

    func goBack() {
        guard let webView else { return }
        if webView.canGoBack {
            webView.goBack()
        } else {
            webView.evaluateJavaScript("if (window.history.length > 1) { window.history.back(); true } else { false }")
        }
    }

    func goForward() {
        guard let webView else { return }
        if webView.canGoForward {
            webView.goForward()
        } else {
            webView.evaluateJavaScript("window.history.forward(); true")
        }
    }
}

private struct WebContainer: NSViewRepresentable {
    let shortcut: ShortcutItem
    let url: URL
    let requestVersion: Int
    let controls: BrowserNavigationControls

    func makeCoordinator() -> Coordinator {
        Coordinator(controls: controls, handledRequestVersion: requestVersion)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = MusicPlaybackController.shared.webView(for: shortcut, configuration: configuration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.customUserAgent = Self.userAgent(for: url)
        MusicPlaybackController.shared.markActive(shortcut, webView: webView)
        controls.attach(webView)
        if webView.url == nil { webView.load(URLRequest(url: url)) }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard requestVersion != context.coordinator.handledRequestVersion else { return }
        context.coordinator.handledRequestVersion = requestVersion
        webView.customUserAgent = Self.userAgent(for: url)
        webView.load(URLRequest(url: url))
    }

    private static func userAgent(for url: URL) -> String {
        let domesticHosts = [
            "v.qq.com", "www.iqiyi.com", "www.youku.com", "www.mgtv.com",
            "www.bilibili.com", "www.miguvideo.com", "tv.sohu.com",
            "y.qq.com", "music.163.com"
        ]
        if let host = url.host()?.lowercased(), domesticHosts.contains(host) {
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
        }
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15"
    }

    @MainActor
    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        private let controls: BrowserNavigationControls
        var handledRequestVersion: Int

        init(controls: BrowserNavigationControls, handledRequestVersion: Int) {
            self.controls = controls
            self.handledRequestVersion = handledRequestVersion
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            controls.update()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            controls.update()
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let requestURL = navigationAction.request.url {
                webView.load(URLRequest(url: requestURL))
            }
            return nil
        }
    }
}
