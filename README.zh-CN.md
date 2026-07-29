# Writion 创作

<p align="center">

<a href="README.md">
<img src="https://img.shields.io/badge/Language-English-blue?style=for-the-badge">
</a>

<a href="README.zh-CN.md">
<img src="https://img.shields.io/badge/%E8%AF%AD%E8%A8%80-%E4%B8%AD%E6%96%87-red?style=for-the-badge">
</a>

</p>

<p align="center">

<a href="https://github.com/nhx100218/Writion-iOS/actions/workflows/build.yml">
<img src="https://github.com/nhx100218/Writion-iOS/actions/workflows/build.yml/badge.svg?branch=main">
</a>

<a href="https://github.com/nhx100218/Writion-iOS/releases">
<img src="https://img.shields.io/github/downloads/nhx100218/Writion-iOS/total?label=%E4%B8%8B%E8%BD%BD&style=flat">
</a>

<a href="https://github.com/nhx100218/Writion-iOS/releases/">
<img src="https://img.shields.io/github/v/release/nhx100218/Writion-iOS?style=flat">
</a>

<a href="https://raw.githubusercontent.com/nhx100218/Writion-iOS/main/LICENSE">
<img src="https://img.shields.io/github/license/nhx100218/Writion-iOS?style=flat">
</a>

<img src="https://img.shields.io/github/last-commit/nhx100218/Writion-iOS?color=c78aff&label=%E6%9C%80%E8%BF%91%E6%8F%90%E4%BA%A4&style=flat">

</p>

## 🌟 核心亮点

基于 SwiftUI 原生框架，为作者打造的文档型书籍写作 App。核心特性：

- **文档型架构**: `DocumentGroup` + `FileDocument`，每本书独立管理为 `.md` 文件，本地存储。
- **类 VSCode 侧边栏编辑器**: 左侧章节列表（删除 / 重命名 / 拖拽排序）+ 右侧 Markdown 正文编辑区，支持实时预览切换。
- **多章节 & 间章**: "普通章节"与"间章"独立编号。章节列表支持批量选择删除。
- **导入 & 导出**: 通过粘贴 Writion 格式 .md 文本导入；导出 `.md` 或发布为 `.epub` 电子书。
- **完整汉化**: 75+ 条多语言字符串，涵盖 6 种语言（简体中文 / 英语 / 德语 / 阿拉伯语 / 希伯来语 / 泰语）。
- **导航栏标题菜单**: 重命名书籍 / 修改作者 / 发布为 EPUB，集成于系统标题栏菜单。
- **iPad 分栏视图**: `NavigationSplitView` 侧边栏适配 iPad；`NavigationStack` 适配 iPhone。
- **深色模式自适应背景**: 浅色模式暖米黄纸质感渐变，深色模式深沉暖棕渐变。

> ⚠️ 说明：导入功能为实验性功能，可能导致书籍名丢失，请谨慎使用。导入后建议检查并修正书名。


## 🚀 快速上手指南

### 设备要求

| 类型 | 系统版本 | 设备 |
|------|----------|------|
| **最低配置** | iOS 26.0+ / macOS 26.0+ | iPhone / iPad / Apple Silicon Mac |

### 从源码构建

1. 克隆仓库
2. 在 Xcode 中打开 `Writion/Writion.xcodeproj`
3. 选择 **Writion** scheme
4. 构建并运行（`⌘R`）

### 侧载（Sideload）准备
1. **AltStore/SideStore**（首选）：需定期重签名，首次设置需电脑/Wi-Fi；不支持「分发证书签名服务」，仅兼容「开发证书」
2. **NB 助手**（替代）：需定期重签名，首次设置需电脑/Wi-Fi；支持「分发证书签名服务」，有广告。[官方链接](https://nbtool8.com)
> ⚠️ 安全提示：仅从官方/可信来源下载侧载工具及 IPA；非官方软件导致的设备问题，本人不承担责任；越狱设备虽支持永久签名，但不建议越狱日常设备。


### 📥 安装步骤
#### 1. 每日构建（AltStore/SideStore/NB 助手 渠道）
1. 前往 [GitHub Actions 标签页](https://github.com/nhx100218/Writion-iOS/actions) 下载 IPA 安装包
2. (正常的安装步骤)

#### 2. 正式版（AltStore/SideStore/NB 助手 渠道）
1. 前往 [GitHub Releases 标签页](https://github.com/nhx100218/Writion-iOS/releases/) 下载 IPA 安装包
2. (正常的安装步骤)

> ⚠️ 注意：每日构建可能不稳定，请优先选择最新构建，若无法安装/运行游戏失败，再选择更早构建运行，构建失败的action不要下载。


## 📦 技术架构

| 模块 | 技术方案 |
|------|----------|
| 应用入口 | `AppLauncher` → `WritionLicenseApp` / `WritionDocumentApp` |
| 文档模型 | `FileDocument` 协议（`BookDocument`） |
| 场景管理 | `DocumentGroup` + `DocumentGroupLaunchScene` |
| 数据格式 | 自定义 Markdown `.md`（新版: `#Start#...#End#`，旧版: `###...###`）|
| 章节 | `Chapter` 结构体（模式 / 编号 / 标题 / 内容） |
| 侧边栏编辑器 | `NavigationSplitView`（iPad）/ `NavigationStack`（iPhone） |
| EPUB 导出 | 内置 ZIP 写入器 + Markdown→HTML 转换器 |
| 缩略图 | `UIDocumentProperties` UIKit 桥接 |
| 多语言 | `Localizable.xcstrings`（9 语言，75+ 键值） |


## 🙏 致谢

本项目基于 Apple 官方示例工程及文档构建，特别感谢以下资源：

- [Building a Document-Based App with SwiftUI](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui)
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Building a Document-Based App Using SwiftData](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata)
- [Toolbars — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/toolbars)
- [Evolve your document launch experience (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10132/)


## 📄 许可证

本项目基于 [MIT 协议](LICENSE) 开源。


## CI 构件

GitHub Action 会导出未签名的 IPA 文件 `Writion.ipa`。
