/*
 Writion — 书籍创作 App
 单章节 Markdown 编辑器
*/

import SwiftUI

struct ChapterEditorView: View {
    @Binding var chapter: Chapter

    @State private var isPreviewing = false
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 章节标题区
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
                        editedTitle = chapter.title; isEditingTitle = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(chapter.title).font(.title).fontWeight(.bold)
                            Image(systemName: "pencil").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // 正文：编辑/预览
            if isPreviewing {
                markdownPreview
            } else {
                markdownEditor
            }
        }
        .frame(maxWidth: 800, alignment: .leading)
        .toolbar {
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

    // MARK: - Markdown 编辑（撑满剩余空间）

    private var markdownEditor: some View {
        TextEditor(text: $chapter.content)
            .font(.body)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.automatic)
            .overlay(alignment: .topLeading) {
                if chapter.content.isEmpty {
                    Text("开始编写章节内容...")
                        .font(.body).foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 6)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
    }

    // MARK: - Markdown 预览

    @ViewBuilder
    private var markdownPreview: some View {
        ScrollView {
            if chapter.content.isEmpty {
                Text("切换到编辑模式开始编写")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.top, 16)
            } else {
                Text(.init(chapter.content))
                    .font(.body).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.vertical, 16)
            }
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
