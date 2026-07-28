/*
 Writion — 书籍创作 App
*/

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 启动器

@main
struct AppLauncher {
    static func main() {
        if UserDefaults.standard.bool(forKey: "hasAcceptedNWsLicense") {
            WritionDocumentApp.main()
        } else {
            WritionLicenseApp.main()
        }
    }
}

// MARK: - 许可 App

struct WritionLicenseApp: App {
    @State private var hasSeenFeatureHighlights = false
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenFeatureHighlights {
                    CreatorFeaturesView(onContinue: {
                        UserDefaults.standard.set(true, forKey: "hasAcceptedNWsLicense"); exit(0)
                    }).transition(.featureStageTransition).statusBarHidden(false)
                } else {
                    LicenseAgreementView(
                        onAgree: { withAnimation(.easeInOut(duration: 0.35)) { hasSeenFeatureHighlights = true } },
                        onClose: { exit(0) }
                    ).transition(.licenseStageTransition).statusBarHidden(true)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: hasSeenFeatureHighlights)
        }
    }
}

// MARK: - 导入管理器

@Observable final class ImportManager {
    var isShowingImporter = false
    var importContinuation: CheckedContinuation<BookDocument?, any Error>?
}

// MARK: - 文档 App

struct WritionDocumentApp: App {
    @State private var importManager = ImportManager()

    var body: some Scene {
        #if os(iOS)
        DocumentGroupLaunchScene {
            HStack(spacing: 16) {
                NewDocumentButton("新建书籍")
                NewDocumentButton("导入书籍", for: BookDocument.self) {
                    try await withCheckedThrowingContinuation { (c: CheckedContinuation<BookDocument?, any Error>) in
                        importManager.importContinuation = c
                        importManager.isShowingImporter = true
                    }
                }
                .fullScreenCover(isPresented: $importManager.isShowingImporter) {
                    ImportBookSheet { mdText in
                        importManager.isShowingImporter = false
                        defer { importManager.importContinuation = nil }
                        guard let mdText else {
                            importManager.importContinuation?.resume(throwing: CancellationError())
                            return
                        }
                        let bookData = BookDocument.parseBook(from: mdText)
                        guard !bookData.bookName.isEmpty else {
                            importManager.importContinuation?.resume(throwing: CancellationError())
                            return
                        }
                        let doc = BookDocument(bookData: bookData)
                        importManager.importContinuation?.resume(returning: doc)
                    }
                }
            }
        } background: {
            LaunchBackground().ignoresSafeArea()
        }
        #endif

        DocumentGroup(newDocument: BookDocument()) { configuration in
            BookEditorView(
                document: configuration.$document,
                fileURL: configuration.fileURL
            )
        }
    }
}

// MARK: - 导入弹窗

private struct ImportBookSheet: View {
    @State private var mdText = ""
    @State private var errorMessage: String?
    let onComplete: (String?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let error = errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.caption)
                }
                Label("导入功能可能导致书籍名丢失，请谨慎使用。导入后建议检查并修正书名。",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
                TextEditor(text: $mdText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topLeading) {
                        if mdText.isEmpty {
                            exampleOverlay
                        }
                    }
            }
            .padding()
            .navigationTitle("导入书籍").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onComplete(nil) } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let t = mdText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if t.isEmpty { errorMessage = String(localized: "请输入有效的书籍内容。"); return }
                        if BookDocument.parseBook(from: t).bookName.isEmpty {
                            errorMessage = String(localized: "无法识别 Writion 格式，请检查内容后重试。"); return
                        }
                        onComplete(t)
                    } label: { Image(systemName: "checkmark").fontWeight(.semibold) }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var exampleOverlay: some View {
        Text("""
        #Start#
        Book Name: 示例书名
        Author: 作者名
        #Text_Page#
        ------------
        Mode: Normal
        Chapters: 1
        ------
        Title: 第一章
        ------
        Content:
        正文内容（Markdown）
        ------
        Mode: Special
        Chapters: 1
        ------
        Title: 间章标题
        ------
        Content:
        间章内容
        ------------
        #End#
        """)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.tertiary).padding(8).allowsHitTesting(false)
    }
}

// MARK: - 背景

private struct LaunchBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.07, blue: 0.05),
                         Color(red: 0.16, green: 0.11, blue: 0.08),
                         Color(red: 0.12, green: 0.08, blue: 0.06)],
                startPoint: .top, endPoint: .bottom
            )
        } else {
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.93, blue: 0.88),
                         Color(red: 0.93, green: 0.89, blue: 0.82),
                         Color(red: 0.88, green: 0.83, blue: 0.76)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - 动画

private extension AnyTransition {
    static var licenseStageTransition: AnyTransition {
        .asymmetric(insertion: .identity, removal: .move(edge: .bottom))
    }
    static var featureStageTransition: AnyTransition {
        .asymmetric(insertion: .scale(scale: 1.08).combined(with: .opacity),
                    removal: .scale(scale: 1.12).combined(with: .opacity))
    }
}
