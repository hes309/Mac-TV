import AppKit
import SwiftUI

struct AppLibraryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [InstalledApplication] {
        guard !query.isEmpty else { return store.installedApplications }
        return store.installedApplications.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("搜索已安装应用", text: $query)
                        .textFieldStyle(.plain)
                    Button("重新扫描") { store.scanApplications() }
                }
                .padding(13)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding()

                if filtered.isEmpty {
                    ContentUnavailableView("没有找到应用", systemImage: "app.dashed", description: Text("也可以把 .app 从 Finder 直接拖到 Mac TV 首页。"))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 18)], spacing: 22) {
                            ForEach(filtered) { app in
                                Button {
                                    store.addApplication(app)
                                } label: {
                                    VStack(spacing: 10) {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                                            .resizable()
                                            .interpolation(.high)
                                            .frame(width: 76, height: 76)
                                        Text(app.name)
                                            .lineLimit(1)
                                            .font(.headline)
                                        Text("添加到首页")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)
                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
                                .draggable(app.url)
                            }
                        }
                        .padding(22)
                    }
                }
            }
            .navigationTitle("应用库")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .onAppear { store.scanApplications() }
        .onExitCommand { dismiss() }
    }
}
