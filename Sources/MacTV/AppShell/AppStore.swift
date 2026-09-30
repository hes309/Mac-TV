import AppKit
import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var state: AppState
    @Published var installedApplications: [InstalledApplication] = []
    @Published var isLibraryPresented = false
    @Published var isProfilePresented = false
    @Published var errorMessage: String?
    @Published var activeWebShortcut: ShortcutItem?

    private let persistence: ShortcutPersisting
    private let launcher: ApplicationLaunching
    private let scanner: InstalledApplicationDiscovering

    init(
        persistence: ShortcutPersisting = JSONStateStore(),
        launcher: ApplicationLaunching = WorkspaceApplicationLauncher(),
        scanner: InstalledApplicationDiscovering = InstalledApplicationScanner()
    ) {
        self.persistence = persistence
        self.launcher = launcher
        self.scanner = scanner
        self.state = (try? persistence.load()) ?? AppState()
        addMissingBuiltInWebShortcuts()
    }

    var shortcuts: [ShortcutItem] { state.shortcuts }
    var profile: UserProfile { state.profile }
    var appearance: AppearanceSettings { state.appearance }

    func updateProfile(name: String, avatarURL: URL?) {
        state.profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "用户" : name
        if let avatarURL { state.profile.avatarBookmark = try? BookmarkResolver.bookmark(for: avatarURL) }
        persist()
    }

    func updateAppearance(_ update: (inout AppearanceSettings) -> Void) {
        update(&state.appearance)
        persist()
    }

    func selectBackground(url: URL, kind: BackgroundKind) {
        updateAppearance {
            $0.backgroundKind = kind
            $0.backgroundBookmark = try? BookmarkResolver.bookmark(for: url)
        }
    }

    func resetBackground() {
        updateAppearance {
            $0.backgroundKind = .builtIn
            $0.backgroundBookmark = nil
        }
    }

    func scanApplications() {
        installedApplications = scanner.discover()
    }

    func addApplication(_ application: InstalledApplication) {
        guard !state.shortcuts.contains(where: { $0.bundleIdentifier == application.bundleIdentifier }) else { return }
        let item = ShortcutItem(
            kind: .application,
            title: application.name,
            subtitle: "已安装的 Mac 应用",
            symbol: "app.fill",
            tintHex: "5876A8",
            bundleIdentifier: application.bundleIdentifier,
            applicationBookmark: try? BookmarkResolver.bookmark(for: application.url)
        )
        let insertionIndex = max(0, state.shortcuts.count - 1)
        state.shortcuts.insert(item, at: insertionIndex)
        persist()
    }

    func importApplication(url: URL) {
        guard url.pathExtension.lowercased() == "app", let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier else {
            errorMessage = "请拖入一个有效的 macOS 应用"
            return
        }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        addApplication(InstalledApplication(id: identifier, name: name, bundleIdentifier: identifier, url: url))
    }

    func moveShortcut(id: UUID, before targetID: UUID) {
        guard id != targetID,
              let source = state.shortcuts.firstIndex(where: { $0.id == id }),
              let target = state.shortcuts.firstIndex(where: { $0.id == targetID }),
              state.shortcuts[source].kind != .add else { return }
        let item = state.shortcuts.remove(at: source)
        let adjusted = source < target ? target - 1 : target
        state.shortcuts.insert(item, at: adjusted)
        persist()
    }

    func rememberFocus(_ id: UUID, layout: HomeLayoutMode) {
        if layout == .circularRow { state.rowFocusID = id } else { state.gridFocusID = id }
        persist()
    }

    func focusID(for layout: HomeLayoutMode) -> UUID? {
        layout == .circularRow ? state.rowFocusID : state.gridFocusID
    }

    func launch(_ shortcut: ShortcutItem) {
        if shortcut.kind == .add {
            scanApplications()
            isLibraryPresented = true
            return
        }
        let entry = RecentLaunch(shortcutID: shortcut.id, title: shortcut.title, launchedAt: .now)
        state.recentLaunches.removeAll { $0.shortcutID == shortcut.id }
        state.recentLaunches.insert(entry, at: 0)
        state.recentLaunches = Array(state.recentLaunches.prefix(30))
        persist()
        if !shortcut.isMusicService {
            MusicPlaybackController.shared.pauseForNonMusicLaunch()
        }
        if shortcut.kind == .web {
            activeWebShortcut = shortcut
            NSApp.activate()
            return
        }
        do {
            try launcher.open(shortcut)
            WindowStageManager.arrange(shortcut)
        }
        catch { errorMessage = error.localizedDescription }
    }

    func closeEmbeddedWeb() {
        activeWebShortcut = nil
    }

    func resolvedAvatarURL() -> URL? { BookmarkResolver.resolve(state.profile.avatarBookmark) }
    func resolvedBackgroundURL() -> URL? { BookmarkResolver.resolve(state.appearance.backgroundBookmark) }

    private func persist() {
        do { try persistence.save(state) }
        catch { errorMessage = "保存设置失败：\(error.localizedDescription)" }
    }

    private func addMissingBuiltInWebShortcuts() {
        var changed = false
        for builtIn in ShortcutItem.builtInWebShortcuts {
            guard let host = builtIn.url?.host()?.lowercased(),
                  let index = state.shortcuts.firstIndex(where: { $0.url?.host()?.lowercased() == host }) else { continue }
            state.shortcuts[index].title = builtIn.title
            state.shortcuts[index].subtitle = builtIn.subtitle
            state.shortcuts[index].symbol = builtIn.symbol
            state.shortcuts[index].tintHex = builtIn.tintHex
            state.shortcuts[index].url = builtIn.url
            changed = true
        }

        let existingHosts = Set(state.shortcuts.compactMap { $0.url?.host()?.lowercased() })
        let missing = ShortcutItem.builtInWebShortcuts.filter {
            guard let host = $0.url?.host()?.lowercased() else { return false }
            return !existingHosts.contains(host)
        }
        if !missing.isEmpty {
            let insertionIndex = state.shortcuts.firstIndex(where: { $0.kind == .add }) ?? state.shortcuts.endIndex
            state.shortcuts.insert(contentsOf: missing, at: insertionIndex)
            changed = true
        }
        if changed { persist() }
    }
}
