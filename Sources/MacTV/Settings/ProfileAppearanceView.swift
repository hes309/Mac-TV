import AppKit
import SwiftUI

struct ProfileAppearanceView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case profile = "个人资料", home = "首页与图标", background = "背景"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .profile: "person.crop.circle.fill"
            case .home: "rectangle.grid.2x2.fill"
            case .background: "photo.on.rectangle.angled"
            }
        }
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Section = .profile
    @State private var name = ""
    @State private var avatarURL: URL?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.05, blue: 0.08), Color(red: 0.08, green: 0.1, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            HStack(spacing: 0) {
                sidebar
                Divider().overlay(.white.opacity(0.08))
                detail
            }
        }
        .foregroundStyle(.white)
        .onAppear { name = store.profile.name; avatarURL = store.resolvedAvatarURL() }
        .onExitCommand { dismiss() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("设置", systemImage: "appletv.fill")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 30)
            VStack(spacing: 10) {
                ForEach(Section.allCases) { section in
                    Button { withAnimation(.snappy(duration: 0.22)) { selection = section } } label: {
                        HStack(spacing: 14) {
                            Image(systemName: section.symbol).font(.system(size: 18, weight: .semibold)).frame(width: 24)
                            Text(section.rawValue).font(.system(size: 16, weight: .semibold))
                            Spacer()
                            if selection == section { Image(systemName: "chevron.right").font(.caption.bold()) }
                        }
                        .padding(.horizontal, 16).frame(height: 52)
                        .background(selection == section ? .white.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain).focusEffectDisabled()
                }
            }.padding(.horizontal, 12)
            Spacer()
            Button { dismiss() } label: {
                Label("返回首页", systemImage: "chevron.backward")
                    .font(.system(size: 14, weight: .semibold)).padding(.horizontal, 16)
                    .frame(height: 44).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain).keyboardShortcut(.cancelAction).padding(16)
        }
        .frame(width: 220).background(.black.opacity(0.18))
    }

    private var detail: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selection.rawValue).font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(detailSubtitle).font(.subheadline).foregroundStyle(.white.opacity(0.52))
                }
                Spacer()
                Button("完成") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.defaultAction)
            }.padding(.horizontal, 34).padding(.vertical, 25)
            ScrollView {
                Group {
                    switch selection {
                    case .profile: profileContent
                    case .home: homeContent
                    case .background: backgroundContent
                    }
                }.padding(.horizontal, 34).padding(.bottom, 30)
            }
        }
    }

    private var detailSubtitle: String {
        switch selection {
        case .profile: "自定义 Mac TV 中显示的身份"
        case .home: "选择适合客厅观看的排列方式"
        case .background: "调整首页的图片、动态效果和氛围"
        }
    }

    private var profileContent: some View {
        VStack(spacing: 18) {
            settingsGroup {
                HStack(spacing: 24) {
                    AvatarView(url: avatarURL, size: 104).shadow(color: .cyan.opacity(0.18), radius: 20)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MAC TV 用户").font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(.white.opacity(0.5))
                        TextField("名字", text: $name).font(.title3.weight(.semibold)).textFieldStyle(.plain)
                            .padding(.horizontal, 15).frame(height: 46)
                            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 11)).onSubmit(saveProfile)
                        HStack {
                            Button("更换头像…") { chooseAvatar() }.buttonStyle(.bordered)
                            Button("保存资料", action: saveProfile).buttonStyle(.borderedProminent)
                        }
                    }
                }.padding(22)
            }
            Text("头像与名字会显示在 Mac TV 首页左上角。").font(.footnote).foregroundStyle(.white.opacity(0.44))
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 6)
        }
    }

    private var homeContent: some View {
        VStack(spacing: 22) {
            settingsGroup(title: "首页布局") {
                ForEach(HomeLayoutMode.allCases) { layout in
                    choiceRow(layout.title, layout == .circularRow ? "横向循环浏览，适合电视和遥控器" : "同时显示更多应用", layout.symbol, store.appearance.layout == layout) {
                        store.updateAppearance { $0.layout = layout }
                    }
                }
            }
            settingsGroup(title: "图标大小") {
                ForEach(AppIconSize.allCases) { size in
                    choiceRow(size.title, iconSizeSubtitle(size), "square.resize", store.appearance.iconSize == size) {
                        store.updateAppearance { $0.iconSize = size }
                    }
                }
            }
            settingsGroup(title: "悬浮应用栏") {
                HStack(spacing: 15) {
                    Image(systemName: "square.grid.2x2.fill").font(.system(size: 19, weight: .semibold)).frame(width: 28).foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("显示悬浮应用按钮").font(.headline)
                        Text("启动后在右下角显示，可展开快速切换应用").font(.caption).foregroundStyle(.white.opacity(0.46))
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.appearance.showFloatingDock },
                        set: { value in store.updateAppearance { $0.showFloatingDock = value } }
                    ))
                    .labelsHidden().toggleStyle(.switch)
                }
                .padding(.horizontal, 18).frame(height: 72)
            }
        }
    }

    private var backgroundContent: some View {
        VStack(spacing: 22) {
            settingsGroup(title: "背景来源") {
                actionRow("选择静态图片", "使用照片作为首页背景", "photo.fill") { chooseBackground(kind: .image) }
                actionRow("选择动态壁纸", "支持常见视频格式", "play.rectangle.fill") { chooseBackground(kind: .video) }
                actionRow("恢复默认背景", "使用 Mac TV 内置渐变背景", "arrow.counterclockwise") { store.resetBackground() }
            }
            settingsGroup(title: "显示效果") {
                HStack {
                    Label("播放动态背景", systemImage: "sparkles.tv").font(.headline)
                    Spacer()
                    Toggle("", isOn: Binding(get: { store.appearance.motionEnabled }, set: { value in store.updateAppearance { $0.motionEnabled = value } }))
                        .labelsHidden().toggleStyle(.switch)
                }.padding(17)
                divider
                sliderRow("背景暗化", Binding(get: { store.appearance.backgroundDim }, set: { value in store.updateAppearance { $0.backgroundDim = value } }), 0...0.75)
                divider
                sliderRow("背景模糊", Binding(get: { store.appearance.backgroundBlur }, set: { value in store.updateAppearance { $0.backgroundBlur = value } }), 0...30)
            }
        }
    }

    private var divider: some View { Divider().overlay(.white.opacity(0.07)) }

    private func settingsGroup<Content: View>(title: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title { Text(title).font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(.white.opacity(0.48)).padding(.horizontal, 18).padding(.vertical, 13) }
            content()
        }
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.09), lineWidth: 1))
    }

    private func choiceRow(_ title: String, _ subtitle: String, _ symbol: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: symbol).font(.system(size: 19, weight: .semibold)).frame(width: 28).foregroundStyle(selected ? .cyan : .white.opacity(0.74))
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.46)) }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.system(size: 21, weight: .semibold)).foregroundStyle(selected ? .cyan : .white.opacity(0.2))
            }.padding(.horizontal, 18).frame(height: 67).contentShape(Rectangle())
        }.buttonStyle(.plain).focusEffectDisabled()
    }

    private func actionRow(_ title: String, _ subtitle: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).frame(width: 28).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.46)) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.32))
            }.padding(.horizontal, 18).frame(height: 67).contentShape(Rectangle())
        }.buttonStyle(.plain).focusEffectDisabled()
    }

    private func sliderRow(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        HStack(spacing: 18) {
            Text(title).font(.headline).frame(width: 90, alignment: .leading)
            Slider(value: value, in: range).tint(.cyan)
            Text("\(Int(value.wrappedValue / range.upperBound * 100))%").monospacedDigit().foregroundStyle(.white.opacity(0.5)).frame(width: 42)
        }.padding(17)
    }

    private func iconSizeSubtitle(_ size: AppIconSize) -> String {
        switch size { case .small: "适合显示更多内容"; case .standard: "清晰度与数量均衡"; case .large: "远距离观看更醒目" }
    }
    private func saveProfile() { store.updateProfile(name: name, avatarURL: avatarURL) }
    private func chooseAvatar() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.image]; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK { avatarURL = panel.url; saveProfile() }
    }
    private func chooseBackground(kind: BackgroundKind) {
        let panel = NSOpenPanel(); panel.allowedContentTypes = kind == .image ? [.image] : [.movie]; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { store.selectBackground(url: url, kind: kind) }
    }
}
