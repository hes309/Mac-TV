# Mac TV

Mac TV 是一款面向客厅大屏的原生 macOS 媒体启动器，以接近 Apple TV 的交互方式统一管理在线视频网站和本机应用。它使用 SwiftUI 与 WebKit 开发，支持键盘方向键、回车和 Esc 操作。

## 功能

- 默认全屏启动，也可切换为窗口模式。
- 单行循环与平铺网格两种首页布局。
- 方向键选择、回车打开、Esc 返回。
- 选中应用时使用放大和光晕反馈。
- 内嵌 YouTube、Netflix、Disney+、Prime Video、Max、哔哩哔哩、腾讯视频、爱奇艺、优酷等常用网站。
- 独立缓存每个网页应用，返回首页后再次打开可恢复页面、滚动位置和浏览历史。
- 内嵌浏览器支持地址输入、前进、后退和最小化。
- QQ 音乐与网易云音乐网页版支持后台播放和悬浮播放控制。
- 可将已安装的 macOS 应用拖入首页作为快捷方式。
- 应用图标使用统一横向卡片比例。
- 自定义用户名、头像、图标尺寸、静态背景和动态壁纸。
- 可选的半透明悬浮应用列表。
- 自动记录最近打开的应用。

## 系统要求

- macOS 14 或更高版本
- Xcode 16 或更高版本

## 构建

1. 使用 Xcode 打开 `MacTV.xcodeproj`。
2. 选择 `MacTV` scheme 和 `My Mac`。
3. 点击运行。

也可以使用命令行构建：

```sh
xcodebuild -project MacTV.xcodeproj -scheme MacTV -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO
```

## 操作

- `←` / `→`：在单行布局中循环选择应用。
- 方向键：在平铺布局中移动选择。
- `Return`：打开当前应用。
- `Esc`：返回首页或退出全屏。
- 点击左上角头像：打开个人资料与外观设置。
- 从 Finder 拖入 `.app`：添加本机应用快捷方式。

## 说明

Mac TV 与 Apple Inc. 无关联。Apple TV、macOS 以及各流媒体服务名称和商标归各自权利人所有。部分网站可能限制 WebKit 登录、DRM 播放或通行密钥功能，实际能力取决于服务提供方。

## 许可证

本项目采用 [MIT License](LICENSE)。
