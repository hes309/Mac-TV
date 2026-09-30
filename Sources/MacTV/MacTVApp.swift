import SwiftUI

@main
struct MacTVApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup("Mac TV") {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 960, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Mac TV") {
                Button("进入或退出全屏") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
            CommandMenu("播放控制") {
                Button("播放或暂停") { MusicPlaybackController.shared.togglePlayPause() }
                    .keyboardShortcut(.space, modifiers: [.option])
                Button("上一曲") { MusicPlaybackController.shared.previous() }
                    .keyboardShortcut(.leftArrow, modifiers: [.option])
                Button("下一曲") { MusicPlaybackController.shared.next() }
                    .keyboardShortcut(.rightArrow, modifiers: [.option])
                Button("收藏") { MusicPlaybackController.shared.toggleLike() }
                    .keyboardShortcut("l", modifiers: [.option])
            }
        }
    }
}
