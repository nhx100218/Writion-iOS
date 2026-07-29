# Writion

<p align="center">

<a href="README.zh-CN.md">
<img src="https://img.shields.io/badge/%E8%AF%AD%E8%A8%80-%E4%B8%AD%E6%96%87-red?style=for-the-badge">
</a>

<a href="README.md">
<img src="https://img.shields.io/badge/Language-English-blue?style=for-the-badge">
</a>

</p>

<p align="center">

<a href="https://github.com/nhx100218/Writion-iOS/actions/workflows/build.yml">
<img src="https://github.com/nhx100218/Writion-iOS/actions/workflows/build.yml/badge.svg?branch=main">
</a>

<a href="https://github.com/nhx100218/Writion-iOS/releases">
<img src="https://img.shields.io/github/downloads/nhx100218/Writion-iOS/total?label=Downloads&style=flat">
</a>

<a href="https://github.com/nhx100218/Writion-iOS/releases/">
<img src="https://img.shields.io/github/v/release/nhx100218/Writion-iOS?style=flat">
</a>

<a href="https://raw.githubusercontent.com/nhx100218/Writion-iOS/main/LICENSE">
<img src="https://img.shields.io/github/license/nhx100218/Writion-iOS?style=flat">
</a>

<img src="https://img.shields.io/github/last-commit/nhx100218/Writion-iOS?color=c78aff&label=Last%20Commit&style=flat">

</p>

## 🌟 Core Highlights

A native SwiftUI document-based book writing app for iOS/iPadOS, designed for authors. Core features:

- **Document-Based Architecture**: Built with `DocumentGroup` + `FileDocument`, each book is an independent `.md` file, saved locally.
- **VSCode-Style Sidebar Editor**: Chapter list sidebar (delete / rename / reorder by drag-and-drop) + Markdown editor area, with live preview toggle.
- **Multi-Chapter & Interlude Support**: Supports "Normal" chapters and "Special" interludes with independent numbering. Batch selection and deletion available.
- **Import & Export**: Paste Writion-format `.md` text to import; export as `.md` or `.epub` for distribution.
- **Full i18n**: 75+ localized strings across 6 languages (en / zh-Hans / de / ar / he / th).
- **Navigation Title Menu**: Rename book / edit author / publish as EPUB, integrated into the system title bar menu.
- **iPad Split View**: `NavigationSplitView` sidebar for iPad; `NavigationStack` for iPhone.
- **Dark Mode Adaptive Background**: Warm paper-tone gradient in light mode, deep brown in dark mode.

> ⚠️ Note: Import is experimental and may cause book name loss. It is recommended to verify and correct the book name after import.


## 🚀 Quick Start Guide

### Requirements

| Type | Version | Devices |
|------|---------|---------|
| **Minimum** | iOS 26.0+ / macOS 26.0+ | iPhone / iPad / Mac with Apple Silicon |

### Build from Source

1. Clone the repository
2. Open `Writion/Writion.xcodeproj` in Xcode
3. Select **Writion** scheme
4. Build and run (`⌘R`)

### Sideload Preparation
Prioritize tools that support "permanent signing + automatic JIT", recommended by priority:
1. **AltStore/SideStore** (Preferred): Requires periodic re-signing, initial setup requires computer/Wi-Fi; does not support "distribution certificate signing service", only compatible with "development certificate" 
2. **NB Tool** (Alternative): Requires periodic re-signing, initial setup requires computer/Wi-Fi; support "distribution certificate signing service"; but have **ads**

> ⚠️ Security Tip: Only download sideloading tools and IPA from official/trusted sources; I am not responsible for device issues caused by unofficial software; Jailbroken devices support permanent signing, but daily jailbreaking is not recommended.

### Installation Steps
#### 1. Daily Build (AltStore/SideStore/NB Tool Channel)
1. Go to [GitHub Actions page](https://github.com/nhx100218/Writion-iOS/actions) to download the IPA installation package
2. (Normal installation steps)

#### 2. Release Build (AltStore/SideStore/NB Tool Channel)
1. Go to [GitHub Releases page](https://github.com/nhx100218/Writion-iOS/releases/) to download the IPA installation package
2. (Normal installation steps)

> ⚠️ Note: The daily build may be unstable. Please give priority to the latest build. If you can't install/run the game and fail, choose to build and run earlier. Don't download the failed action.

## 📦 Technical Architecture

| Component | Technology |
|-----------|------------|
| App Entry | `AppLauncher` → `WritionLicenseApp` / `WritionDocumentApp` |
| Document Model | `FileDocument` protocol (`BookDocument`) |
| Scene | `DocumentGroup` + `DocumentGroupLaunchScene` |
| Data Format | Custom Markdown-based `.md` (new: `#Start#...#End#`, legacy: `###...###`) |
| Chapters | `Chapter` struct (mode / number / title / content) |
| Sidebar Editor | `NavigationSplitView` (iPad) / `NavigationStack` (iPhone) |
| EPUB Export | Built-in ZIP writer + Markdown→HTML converter |
| Thumbnail View | `UIDocumentProperties` UIKit bridge |
| i18n | `Localizable.xcstrings` (9 languages, 75+ keys) |


## 🙏 Acknowledgement

This project is built upon Apple's official sample projects and documentation. Special thanks to:

- [Building a Document-Based App with SwiftUI](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-with-swiftui)
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
- [Building a Document-Based App Using SwiftData](https://developer.apple.com/documentation/swiftui/building-a-document-based-app-using-swiftdata)
- [Toolbars — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/toolbars)
- [Evolve your document launch experience (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10132/)


## 📄 License

This project is open-sourced under the [MIT License](LICENSE).


## CI Artifact

The GitHub Action exports an unsigned IPA artifact named `Writion.ipa`.
