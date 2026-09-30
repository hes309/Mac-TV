import AppKit
import SwiftUI

struct ShortcutIconView: View {
    let shortcut: ShortcutItem
    let size: CGFloat
    let focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            icon

            Text(shortcut.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.white)
                .opacity(focused ? 1 : 0.72)
        }
        .scaleEffect(focused ? 1.14 : 1)
        .offset(y: focused ? -12 : 0)
        .zIndex(focused ? 1 : 0)
        .animation(.snappy(duration: 0.22, extraBounce: 0.08), value: focused)
        .frame(width: size)
    }

    private var icon: some View {
        let cardHeight = size * 0.62
        let cornerRadius = cardHeight * 0.24

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(cardBackground)
            .frame(width: size, height: cardHeight)
            .overlay {
                if shortcut.kind == .application, let image = applicationIcon {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: size * 0.52, height: size * 0.52)
                } else if shortcut.kind == .web {
                    BrandLogoView(shortcut: shortcut, size: size * 0.42)
                } else {
                    Image(systemName: shortcut.symbol)
                        .font(.system(size: size * 0.32, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .brightness(focused ? 0.06 : 0)
            .shadow(color: .white.opacity(focused ? 0.16 : 0), radius: 18)
            .shadow(color: .black.opacity(focused ? 0.58 : 0.28), radius: focused ? 28 : 10, y: focused ? 18 : 7)
    }

    private var cardBackground: AnyShapeStyle {
        if shortcut.kind == .application {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(Color(hex: shortcut.tintHex).gradient)
    }

    private var applicationIcon: NSImage? {
        guard let bundleIdentifier = shortcut.bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) ?? BookmarkResolver.resolve(shortcut.applicationBookmark)
        else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0x555555
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
