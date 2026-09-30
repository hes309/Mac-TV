import SwiftUI

struct BrandLogoView: View {
    let shortcut: ShortcutItem
    let size: CGFloat

    var body: some View {
        if shortcut.kind == .web, let iconName {
            Image(iconName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
            .frame(width: size, height: size)
        } else {
            fallback.frame(width: size, height: size)
        }
    }

    private var fallback: some View {
        Image(systemName: shortcut.symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(size * 0.2)
    }

    private var iconName: String? {
        guard let host = shortcut.url?.host()?.lowercased() else { return nil }
        return [
            "www.youtube.com": "youtube",
            "www.netflix.com": "netflix",
            "www.disneyplus.com": "disneyplus",
            "www.primevideo.com": "primevideo",
            "www.max.com": "max",
            "tv.apple.com": "appletv",
            "www.hulu.com": "hulu",
            "www.paramountplus.com": "paramountplus",
            "v.qq.com": "tencentvideo",
            "www.iqiyi.com": "iqiyi",
            "www.youku.com": "youku",
            "www.mgtv.com": "mangotv",
            "www.bilibili.com": "bilibili",
            "www.miguvideo.com": "miguvideo",
            "tv.sohu.com": "sohuvideo",
            "y.qq.com": "qqmusic",
            "music.163.com": "neteasemusicweb"
        ][host]
    }
}
