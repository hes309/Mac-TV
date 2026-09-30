import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var appliedInitialWindowMode = false

    var body: some View {
        HomeView()
            .sheet(isPresented: $store.isProfilePresented) {
                ProfileAppearanceView()
                    .environmentObject(store)
                    .frame(width: 860, height: 590)
            }
            .sheet(isPresented: $store.isLibraryPresented) {
                AppLibraryView()
                    .environmentObject(store)
                    .frame(minWidth: 760, minHeight: 600)
            }
            .alert("Mac TV", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("好") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .onAppear {
                if store.appearance.showFloatingDock {
                    FloatingAppDockController.shared.show(store: store)
                } else {
                    FloatingAppDockController.shared.hide()
                }
                guard !appliedInitialWindowMode else { return }
                appliedInitialWindowMode = true
                guard store.appearance.windowMode == .fullScreen else { return }
                DispatchQueue.main.async {
                    let window = NSApp.keyWindow ?? NSApp.windows.first
                    if window?.styleMask.contains(.fullScreen) == false {
                        window?.toggleFullScreen(nil)
                    }
                }
            }
            .onChange(of: store.appearance.showFloatingDock) { _, visible in
                if visible {
                    FloatingAppDockController.shared.show(store: store)
                } else {
                    FloatingAppDockController.shared.hide()
                }
            }
            .onDisappear {
                FloatingAppDockController.shared.hide()
            }
    }
}
