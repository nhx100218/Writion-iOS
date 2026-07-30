/*
 Writion — 书籍创作 App
 单章节 Markdown 编辑器
 工具栏: eye/pencil.line 预览 + 撤销/恢复 + …菜单(统计数据/帮助)
*/

import SwiftUI

struct ChapterEditorView: View {
    @Binding var chapter: Chapter

    @State private var isPreviewing = false
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @FocusState private var isTitleFocused: Bool
    @State private var showStatistics = false

    var body: some View {
        VStack(spacing: 0) {
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
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 16)

            Divider()

            if isPreviewing { markdownPreview }
            else { markdownEditor }
        }
        .frame(maxWidth: 800, alignment: .leading)
        .toolbar {
            if isEditingTitle {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { commitTitleEdit() } label: {
                        Image(systemName: "checkmark").fontWeight(.semibold).symbolRenderingMode(.hierarchical).tint(.accentColor)
                    }
                }
            } else {
                // 撤销/恢复 + 预览切换 + …菜单
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        // 撤销
                        Button { } label: { Image(systemName: "arrow.uturn.backward") }
                        // 恢复
                        Button { } label: { Image(systemName: "arrow.uturn.forward") }
                        // 预览切换
                        Button { isPreviewing.toggle() } label: {
                            Image(systemName: isPreviewing ? "pencil.line" : "eye")
                        }
                        // … 菜单
                        Menu {
                            Button { showStatistics = true }
                                label: { Label("统计数据", systemImage: "chart.bar") }
                            Divider()
                            Menu {
                                Label("Markdown 语法", systemImage: "textformat")
                                Text("**粗体**  *斜体*  `代码`").font(.caption).foregroundStyle(.secondary)
                                Divider()
                                Label("章节管理", systemImage: "list.bullet")
                                Text("左滑删除或重命名；菜单栏导出 EPUB/PDF。").font(.caption).foregroundStyle(.secondary)
                            } label: { Label("帮助", systemImage: "questionmark.circle") }
                        } label: {
                            Image(systemName: "ellipsis").font(.body.weight(.bold))
                        }
                    }
                }
            }
        }
        // 统计数据 sheet
        .sheet(isPresented: $showStatistics) {
            StatisticsSheet(chapter: chapter)
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
            .font(.body).scrollContentBackground(.hidden).scrollIndicators(.automatic)
            .overlay(alignment: .topLeading) {
                if chapter.content.isEmpty {
                    Text("开始编写章节内容...").font(.body).foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 6).allowsHitTesting(false)
                }
            }.padding(.horizontal, 16)
    }

    @ViewBuilder private var markdownPreview: some View {
        ScrollView {
            if chapter.content.isEmpty {
                Text("切换到编辑模式开始编写").foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.top, 16)
            } else {
                Text(.init(chapter.content)).font(.body).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.vertical, 16)
            }
        }
    }
}

// MARK: - 统计数据 Sheet

struct StatisticsSheet: View {
    let chapter: Chapter

    var wordCount: Int { chapter.content.split(separator: " ").count + chapter.content.split(separator: "\n").count }
    var charCountWithSpaces: Int { chapter.content.count }
    var charCountWithoutSpaces: Int { chapter.content.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression).count }
    var paragraphCount: Int {
        let paras = chapter.content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return paras.count
    }
    var estimatedPages: Int { max(1, (charCountWithSpaces + 1499) / 1500) }

    var body: some View {
        NavigationStack {
            List {
                Section("章节信息") {
                    LabeledContent("章节标题", value: chapter.title)
                    LabeledContent("章节类型", value: chapter.mode == .special ? String(localized: "间章") : String(localized: "普通章节"))
                }
                Section("统计数据") {
                    LabeledContent("字数") { Text("\(wordCount)").foregroundStyle(.secondary) }
                    LabeledContent("字符数（含空格）") { Text("\(charCountWithSpaces)").foregroundStyle(.secondary) }
                    LabeledContent("字符数（不含空格）") { Text("\(charCountWithoutSpaces)").foregroundStyle(.secondary) }
                    LabeledContent("段落数") { Text("\(paragraphCount)").foregroundStyle(.secondary) }
                    LabeledContent("预估页数") { Text("\(estimatedPages)").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("统计数据").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    //Button("完成") {}.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        ChapterEditorView(chapter: .constant(
            Chapter(number: 1, title: "第一章：启程", content: "# 旅途的开始\n\n**加粗**文字。")
        ))
    }
}
