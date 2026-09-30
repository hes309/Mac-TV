import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focusedID: UUID?
    @FocusState private var profileFocused: Bool

    private var selectedShortcut: ShortcutItem {
        store.shortcuts.first(where: { $0.id == focusedID }) ?? store.shortcuts.first ?? .add
    }

    var body: some View {
        ZStack {
            DynamicBackgroundView(settings: store.appearance, url: store.resolvedBackgroundURL())

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 46)
                    .padding(.top, 40)

                TopShelfView(shortcut: selectedShortcut, isRecent: isRecent(selectedShortcut))
                    .padding(.horizontal, 64)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                Group {
                    if store.appearance.layout == .circularRow {
                        CircularShortcutRow(focusedID: $focusedID)
                    } else {
                        ShortcutGrid(focusedID: $focusedID)
                    }
                }
                .environmentObject(store)
                .frame(maxHeight: store.appearance.layout == .circularRow ? 230 : 390)
                .padding(.bottom, 24)
            }

            if let shortcut = store.activeWebShortcut, let url = shortcut.url {
                EmbeddedBrowserView(shortcut: shortcut, url: url) {
                    store.closeEmbeddedWeb()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(10)
            }
        }
        .background(Color.black)
        .onAppear {
            focusFirstShortcut()
        }
        .onChange(of: focusedID) { _, newValue in
            if let newValue { store.rememberFocus(newValue, layout: store.appearance.layout) }
        }
        .onChange(of: store.appearance.layout) { _, newLayout in
            focusFirstShortcut()
        }
        .onChange(of: store.activeWebShortcut) { previousShortcut, activeShortcut in
            if previousShortcut != nil, activeShortcut == nil {
                focusFirstShortcut()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, store.activeWebShortcut == nil {
                focusFirstShortcut()
            }
        }
        .onExitCommand(perform: handleEscape)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in store.importApplication(url: url) }
            }
            return true
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                store.isProfilePresented = true
            } label: {
                HStack(spacing: 12) {
                    AvatarView(url: store.resolvedAvatarURL(), size: 63, focused: profileFocused)
                    Text(store.profile.name)
                        .font(.headline)
                }
                .padding(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .focused($profileFocused)

            Spacer()

            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.white)
    }

    private func isRecent(_ shortcut: ShortcutItem) -> Bool {
        store.state.recentLaunches.first?.shortcutID == shortcut.id
    }

    private func focusFirstShortcut() {
        guard let firstID = store.shortcuts.first?.id else { return }
        profileFocused = false
        focusedID = nil
        Task { @MainActor in
            await Task.yield()
            focusedID = firstID
        }
    }

    private func handleEscape() {
        if store.activeWebShortcut != nil {
            store.closeEmbeddedWeb()
        } else if store.isProfilePresented {
            store.isProfilePresented = false
        } else if store.isLibraryPresented {
            store.isLibraryPresented = false
        } else {
            let window = NSApp.keyWindow ?? NSApp.windows.first
            if window?.styleMask.contains(.fullScreen) == true {
                store.updateAppearance { $0.windowMode = .window }
                window?.toggleFullScreen(nil)
            }
        }
    }
}

private struct TopShelfView: View {
    let shortcut: ShortcutItem
    let isRecent: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 9) {
            Text(shortcut.title)
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .multilineTextAlignment(.center)
            Text(shortcut.subtitle)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
            if isRecent {
                Label("最近打开", systemImage: "clock.fill")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundStyle(.white)
        .animation(.easeOut(duration: 0.18), value: shortcut.id)
    }
}

struct AvatarView: View {
    let url: URL?
    let size: CGFloat
    var focused = false

    var body: some View {
        Group {
            if let url, let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [.cyan.opacity(0.9), .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "person.fill").font(.system(size: size * 0.45))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    focused
                        ? AnyShapeStyle(LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.65)),
                    lineWidth: focused ? 3.5 : 2
                )
                .padding(focused ? -5 : 0)
        }
        .shadow(color: .cyan.opacity(focused ? 0.75 : 0), radius: 14)
        .shadow(color: .purple.opacity(focused ? 0.45 : 0), radius: 22)
        .scaleEffect(focused ? 1.08 : 1)
        .animation(.snappy(duration: 0.2), value: focused)
    }
}
