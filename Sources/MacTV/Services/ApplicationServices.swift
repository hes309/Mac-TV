import AppKit
import Foundation

@MainActor
protocol ApplicationLaunching {
    func open(_ shortcut: ShortcutItem) throws
}

@MainActor
struct WorkspaceApplicationLauncher: ApplicationLaunching {
    enum LaunchError: LocalizedError {
        case invalidURL
        case safariUnavailable
        case applicationUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidURL: "快捷方式地址无效"
            case .safariUnavailable: "找不到 Safari"
            case .applicationUnavailable: "应用已经移动或卸载"
            }
        }
    }

    func open(_ shortcut: ShortcutItem) throws {
        switch shortcut.kind {
        case .web:
            guard let url = shortcut.url else { throw LaunchError.invalidURL }
            guard let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") else {
                throw LaunchError.safariUnavailable
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: safari,
                configuration: configuration,
                completionHandler: nil
            )
        case .application:
            let savedURL = BookmarkResolver.resolve(shortcut.applicationBookmark)
            let bundleURL = shortcut.bundleIdentifier.flatMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
            guard let applicationURL = bundleURL ?? savedURL else { throw LaunchError.applicationUnavailable }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(
                at: applicationURL,
                configuration: configuration,
                completionHandler: nil
            )
        case .add:
            break
        }
    }
}

protocol InstalledApplicationDiscovering {
    func discover() -> [InstalledApplication]
}

struct InstalledApplicationScanner: InstalledApplicationDiscovering {
    func discover() -> [InstalledApplication] {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications", directoryHint: .isDirectory)
        ]
        var seen = Set<String>()
        var results: [InstalledApplication] = []

        for root in roots {
            guard let urls = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for url in urls where url.pathExtension.lowercased() == "app" {
                guard let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier else { continue }
                guard seen.insert(identifier).inserted else { continue }
                let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                results.append(InstalledApplication(id: identifier, name: displayName, bundleIdentifier: identifier, url: url))
            }
        }
        return results.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
