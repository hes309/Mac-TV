import AppKit
import ApplicationServices

enum WindowStageManager {
    @MainActor
    static func arrange(_ shortcut: ShortcutItem) {
        let bundleIdentifier: String?
        switch shortcut.kind {
        case .web:
            bundleIdentifier = "com.apple.Safari"
        case .application:
            bundleIdentifier = shortcut.bundleIdentifier
        case .add:
            bundleIdentifier = nil
        }
        guard let bundleIdentifier else { return }

        guard AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first,
                  let screen = NSScreen.main else { return }

            let application = AXUIElementCreateApplication(app.processIdentifier)
            var windowsValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                  let windows = windowsValue as? [AXUIElement],
                  let window = windows.first else { return }

            let visible = screen.visibleFrame
            let rightDockSpace: CGFloat = 286
            let margin: CGFloat = 22
            var targetSize = CGSize(
                width: max(640, visible.width - rightDockSpace - margin * 2),
                height: max(480, visible.height - margin * 2)
            )
            var targetOrigin = CGPoint(
                x: visible.minX + margin,
                y: screen.frame.maxY - (visible.maxY - margin)
            )

            if let position = AXValueCreate(.cgPoint, &targetOrigin) {
                AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
            }
            if let size = AXValueCreate(.cgSize, &targetSize) {
                AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, size)
            }
            app.activate()
        }
    }

}
