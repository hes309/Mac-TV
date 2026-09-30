import AppKit
import SwiftUI

@MainActor
final class FloatingAppDockController {
    static let shared = FloatingAppDockController()

    private var panel: NSPanel?
    private var expanded = true
    private var dragStartOrigin: CGPoint?

    private init() {}

    func show(store: AppStore) {
        expanded = false
        if panel == nil {
            let panel = NSPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .floating
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isMovable = false
            panel.becomesKeyOnlyIfNeeded = true
            self.panel = panel
        }
        rebuildContent(store: store)
        positionPanel(animated: false)
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func setExpanded(_ value: Bool, store: AppStore) {
        expanded = value
        rebuildContent(store: store)
        positionPanel(animated: true)
    }

    private func rebuildContent(store: AppStore) {
        let view = FloatingAppDockView(
            store: store,
            expanded: expanded,
            setExpanded: { [weak self] value in self?.setExpanded(value, store: store) },
            moveCollapsedButton: { [weak self] translation, ended in
                self?.moveCollapsedButton(translation: translation, ended: ended)
            }
        )
        panel?.contentView = NSHostingView(rootView: view)
    }

    private func positionPanel(animated: Bool) {
        guard let panel, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = expanded ? CGSize(width: 242, height: min(680, visible.height - 56)) : CGSize(width: 62, height: 62)
        let origin = expanded
            ? CGPoint(x: visible.maxX - size.width - 28, y: visible.midY - size.height / 2)
            : CGPoint(x: visible.maxX - size.width - 28, y: visible.minY + 86)
        panel.setFrame(NSRect(origin: origin, size: size), display: true, animate: animated)
    }

    private func moveCollapsedButton(translation: CGSize, ended: Bool) {
        guard !expanded, let panel, let screen = panel.screen ?? NSScreen.main else { return }
        if dragStartOrigin == nil { dragStartOrigin = panel.frame.origin }
        guard let start = dragStartOrigin else { return }

        let visible = screen.visibleFrame
        let proposed = CGPoint(x: start.x + translation.width, y: start.y - translation.height)
        let clamped = CGPoint(
            x: min(max(proposed.x, visible.minX + 12), visible.maxX - panel.frame.width - 12),
            y: min(max(proposed.y, visible.minY + 12), visible.maxY - panel.frame.height - 12)
        )
        panel.setFrameOrigin(clamped)
        if ended { dragStartOrigin = nil }
    }
}

private struct FloatingAppDockView: View {
    @ObservedObject var store: AppStore
    @ObservedObject private var music = MusicPlaybackController.shared
    let expanded: Bool
    let setExpanded: (Bool) -> Void
    let moveCollapsedButton: (CGSize, Bool) -> Void

    var body: some View {
        Group {
            if expanded { expandedDock } else { collapsedButton }
        }
        .preferredColorScheme(.dark)
    }

    private var expandedDock: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("应用").font(.headline)
                    Text("Mac TV").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { setExpanded(false) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .help("隐藏应用栏")
            }

            Divider().opacity(0.45)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(store.shortcuts) { shortcut in
                        dockItem(shortcut)
                    }
                }
            }

            if music.serviceName != nil {
                miniPlayer
            }
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .padding(2)
    }

    private var miniPlayer: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "music.note").foregroundStyle(.cyan)
                Text(music.serviceName ?? "音乐").font(.caption.weight(.semibold)).lineLimit(1)
                Spacer()
                Button { music.toggleLike() } label: {
                    Image(systemName: music.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(music.isLiked ? .pink : .white)
                }.buttonStyle(.plain)
            }
            HStack(spacing: 22) {
                Button { music.previous() } label: { Image(systemName: "backward.fill") }
                Button { music.togglePlayPause() } label: {
                    Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 32, height: 32).background(.white, in: Circle()).foregroundStyle(.black)
                }
                Button { music.next() } label: { Image(systemName: "forward.fill") }
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.96), in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(.cyan.opacity(0.22), lineWidth: 1))
    }

    private func dockItem(_ shortcut: ShortcutItem) -> some View {
        Button { store.launch(shortcut) } label: {
            HStack(spacing: 12) {
                dockIcon(shortcut)
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortcut.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(shortcut.kind == .web ? "网页" : shortcut.kind == .application ? "Mac 应用" : "添加快捷方式")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.19, green: 0.23, blue: 0.30).opacity(0.92),
                    Color(red: 0.12, green: 0.15, blue: 0.21).opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 5, y: 3)
    }

    @ViewBuilder
    private func dockIcon(_ shortcut: ShortcutItem) -> some View {
        if shortcut.kind == .application,
           let bundleIdentifier = shortcut.bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) ?? BookmarkResolver.resolve(shortcut.applicationBookmark) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable().scaledToFit()
                .frame(width: 36, height: 36)
        } else if shortcut.kind == .web {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: shortcut.tintHex).gradient)
                BrandLogoView(shortcut: shortcut, size: 25)
            }
            .frame(width: 38, height: 38)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: shortcut.tintHex).gradient)
                Image(systemName: shortcut.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)
        }
    }

    private var collapsedButton: some View {
        Image(systemName: "square.grid.2x2.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))
            .shadow(color: .black.opacity(0.38), radius: 16, y: 7)
            .contentShape(Circle())
            .onTapGesture { setExpanded(true) }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { moveCollapsedButton($0.translation, false) }
                    .onEnded { moveCollapsedButton($0.translation, true) }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { setExpanded(true) }
        .help("显示应用栏")
    }
}
