/*
 Writion — 书籍创作 App
 单章节 Markdown 编辑器

 - 章节标题点击进入行内编辑，编辑时"完成"按钮替代编辑/预览按钮
 - 预览/编辑切换图标使用 square.and.pencil
*/

import SwiftUI

struct ChapterEditorView: View {
    @Binding var chapter: Chapter

    @State private var isPreviewing = false
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @FocusState private var isTitleFocused: Bool

    private let editorMaxWidth: CGFloat = 800

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(modeAndNumberText(chapter))
                        .font(.subheadline).foregroundStyle(.secondary)

                    if isEditingTitle {
                        TextField("章节标题", text: $editedTitle)
                            .font(.title).fontWeight(.bold)
                            .focused($isTitleFocused)
                            .onSubmit { commitTitleEdit() }
                            .onAppear { isTitleFocused = true }
                    } else {
                        Button {
                            editedTitle = chapter.title
                            isEditingTitle = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(chapter.title).font(.title).fontWeight(.bold)
                                Image(systemName: "pencil").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 16)

                Divider().padding(.bottom, 16)

                if isPreviewing {
                    markdownPreview
                } else {
                    markdownEditor
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 24)
            .frame(maxWidth: editorMaxWidth, alignment: .leading)
        }
        .background(.background)
        .toolbar {
            // 编辑标题模式 → 仅显示"完成"勾号
            // 非编辑模式 → 显示预览/编辑切换按钮（square.and.pencil）
            if isEditingTitle {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { commitTitleEdit() } label: {
                        Image(systemName: "checkmark").fontWeight(.semibold).symbolRenderingMode(.hierarchical)
                    }
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPreviewing.toggle() } label: {
                        Label(isPreviewing ? "编辑" : "预览",
                              systemImage: isPreviewing ? "square.and.pencil" : "eye")
                    }
                }
            }
        }
    }

    private func commitTitleEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { chapter.title = trimmed }
        isEditingTitle = false
    }

    private func modeAndNumberText(_ chapter: Chapter) -> String {
        if chapter.mode == .special {
            return "\(String(localized: "间章")) \(chapter.number)"
        }
        return String(format: String(localized: "第%lld章"), chapter.number)
    }

    private var markdownEditor: some View {
        TextEditor(text: $chapter.content)
            .font(.body).textEditorStyle(.plain).scrollIndicators(.automatic)
            .frame(minHeight: 300)
            .overlay {
                if chapter.content.isEmpty {
                    Text("开始编写章节内容...")
                        .font(.body).foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, 7).padding(.leading, 6).allowsHitTesting(false)
                }
            }
    }

    @ViewBuilder
    private var markdownPreview: some View {
        if chapter.content.isEmpty {
            // 纯文字占位，无图标
            Text("切换到编辑模式开始编写")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(.init(chapter.content))
                .font(.body).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        ChapterEditorView(chapter: .constant(
            Chapter(number: 1, title: "第一章：启程", content: "# 旅途的开始\n\n**加粗**文字。")
        ))
    }
}
