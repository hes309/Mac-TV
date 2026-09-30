import Foundation

enum HomeLayoutMode: String, Codable, CaseIterable, Identifiable {
    case circularRow
    case grid

    var id: String { rawValue }
    var title: String { self == .circularRow ? "单行循环" : "平铺网格" }
    var symbol: String { self == .circularRow ? "rectangle.split.3x1" : "square.grid.3x2" }
}

enum AppIconSize: String, Codable, CaseIterable, Identifiable {
    case small
    case standard
    case large

    var id: String { rawValue }
    var title: String {
        switch self { case .small: "小"; case .standard: "标准"; case .large: "大" }
    }
    var points: CGFloat {
        switch self { case .small: 112; case .standard: 142; case .large: 176 }
    }
}

enum BackgroundKind: String, Codable, CaseIterable {
    case builtIn
    case image
    case video
}

enum WindowPresentationMode: String, Codable, CaseIterable, Identifiable {
    case fullScreen
    case window

    var id: String { rawValue }
    var title: String { self == .fullScreen ? "全屏模式" : "窗口模式" }
    var symbol: String { self == .fullScreen ? "arrow.up.left.and.arrow.down.right" : "macwindow" }
}

struct UserProfile: Codable, Equatable {
    var name: String
    var avatarBookmark: Data?

    static var initial: UserProfile {
        let fullName = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        return UserProfile(name: fullName.isEmpty ? "用户" : fullName, avatarBookmark: nil)
    }
}

struct AppearanceSettings: Codable, Equatable {
    var iconSize: AppIconSize = .standard
    var layout: HomeLayoutMode = .circularRow
    var backgroundKind: BackgroundKind = .builtIn
    var backgroundBookmark: Data?
    var backgroundBlur: Double = 0
    var backgroundDim: Double = 0.25
    var motionEnabled: Bool = true
    var windowMode: WindowPresentationMode = .fullScreen
    var showFloatingDock: Bool = false

    private enum CodingKeys: String, CodingKey {
        case iconSize, layout, backgroundKind, backgroundBookmark
        case backgroundBlur, backgroundDim, motionEnabled, windowMode, showFloatingDock
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iconSize = try container.decodeIfPresent(AppIconSize.self, forKey: .iconSize) ?? .standard
        layout = try container.decodeIfPresent(HomeLayoutMode.self, forKey: .layout) ?? .circularRow
        backgroundKind = try container.decodeIfPresent(BackgroundKind.self, forKey: .backgroundKind) ?? .builtIn
        backgroundBookmark = try container.decodeIfPresent(Data.self, forKey: .backgroundBookmark)
        backgroundBlur = try container.decodeIfPresent(Double.self, forKey: .backgroundBlur) ?? 0
        backgroundDim = try container.decodeIfPresent(Double.self, forKey: .backgroundDim) ?? 0.25
        motionEnabled = try container.decodeIfPresent(Bool.self, forKey: .motionEnabled) ?? true
        windowMode = try container.decodeIfPresent(WindowPresentationMode.self, forKey: .windowMode) ?? .fullScreen
        showFloatingDock = try container.decodeIfPresent(Bool.self, forKey: .showFloatingDock) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iconSize, forKey: .iconSize)
        try container.encode(layout, forKey: .layout)
        try container.encode(backgroundKind, forKey: .backgroundKind)
        try container.encodeIfPresent(backgroundBookmark, forKey: .backgroundBookmark)
        try container.encode(backgroundBlur, forKey: .backgroundBlur)
        try container.encode(backgroundDim, forKey: .backgroundDim)
        try container.encode(motionEnabled, forKey: .motionEnabled)
        try container.encode(windowMode, forKey: .windowMode)
        try container.encode(showFloatingDock, forKey: .showFloatingDock)
    }
}

enum ShortcutKind: String, Codable {
    case web
    case application
    case add
}

struct ShortcutItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var kind: ShortcutKind
    var title: String
    var subtitle: String
    var symbol: String
    var tintHex: String
    var url: URL?
    var bundleIdentifier: String?
    var applicationBookmark: Data?

    init(
        id: UUID = UUID(),
        kind: ShortcutKind,
        title: String,
        subtitle: String,
        symbol: String,
        tintHex: String,
        url: URL? = nil,
        bundleIdentifier: String? = nil,
        applicationBookmark: Data? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.tintHex = tintHex
        self.url = url
        self.bundleIdentifier = bundleIdentifier
        self.applicationBookmark = applicationBookmark
    }
}

struct InstalledApplication: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let url: URL
}

struct RecentLaunch: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var shortcutID: UUID
    var title: String
    var launchedAt: Date
}

struct AppState: Codable, Equatable {
    var profile: UserProfile = .initial
    var appearance = AppearanceSettings()
    var shortcuts: [ShortcutItem] = ShortcutItem.defaults
    var recentLaunches: [RecentLaunch] = []
    var rowFocusID: UUID?
    var gridFocusID: UUID?
}

extension ShortcutItem {
    static let add = ShortcutItem(
        id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
        kind: .add,
        title: "添加应用",
        subtitle: "浏览已安装应用",
        symbol: "plus",
        tintHex: "596273"
    )

    static let builtInWebShortcuts: [ShortcutItem] = [
        web("YouTube", "play.fill", "FF0033", "https://www.youtube.com"),
        web("Netflix", "n.square.fill", "E50914", "https://www.netflix.com"),
        web("Disney+", "sparkles.tv.fill", "1C5DFF", "https://www.disneyplus.com"),
        web("Prime Video", "play.tv.fill", "00A8E1", "https://www.primevideo.com"),
        web("Max", "m.square.fill", "6B49FF", "https://www.max.com"),
        web("Apple TV+", "appletv.fill", "202020", "https://tv.apple.com"),
        web("Hulu", "h.square.fill", "1CE783", "https://www.hulu.com"),
        web("Paramount+", "mountain.2.fill", "0064FF", "https://www.paramountplus.com"),
        web("腾讯视频", "play.rectangle.fill", "FF6A00", "https://v.qq.com"),
        web("爱奇艺", "play.square.fill", "00BE06", "https://www.iqiyi.com"),
        web("优酷", "play.circle.fill", "00A8FF", "https://www.youku.com"),
        web("芒果TV", "play.tv.fill", "FF7A00", "https://www.mgtv.com"),
        web("哔哩哔哩", "tv.fill", "FB7299", "https://www.bilibili.com"),
        web("咪咕视频", "video.fill", "E94475", "https://www.miguvideo.com"),
        web("搜狐视频", "film.fill", "2B79FF", "https://tv.sohu.com"),
        web("QQ音乐", "music.note", "31C27C", "https://y.qq.com"),
        web("网易云音乐", "music.note.list", "E81738", "https://music.163.com"),
        web("浏览器", "globe", "2488FF", "https://www.google.com")
    ]

    static let defaults: [ShortcutItem] = builtInWebShortcuts + [.add]

    private static func web(_ title: String, _ symbol: String, _ tint: String, _ address: String) -> ShortcutItem {
        ShortcutItem(
            kind: .web,
            title: title,
            subtitle: "在 Mac TV 中打开",
            symbol: symbol,
            tintHex: tint,
            url: URL(string: address)
        )
    }
}

extension ShortcutItem {
    var isMusicService: Bool {
        guard let host = url?.host()?.lowercased() else { return false }
        return host == "y.qq.com" || host == "music.163.com"
    }

    var isBrowserShortcut: Bool {
        title == "浏览器" && url?.host()?.lowercased() == "www.google.com"
    }
}
