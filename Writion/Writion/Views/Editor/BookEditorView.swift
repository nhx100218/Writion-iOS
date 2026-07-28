/*
 Writion — 书籍创作 App
 编辑模式：原生 EditButton + @Environment(\.editMode)
 iPad：编辑时切换 iPhone 样式
*/

import SwiftUI
import UniformTypeIdentifiers

struct BookEditorView: View {
    @Binding var document: BookDocument
    let fileURL: URL?

    @State private var selectedChapterID: UUID?
    @State private var renamingChapterID: UUID?

    @State private var isShowingBookInfoOnStart = false
    @State private var isShowingPublish = false
    @State private var isShowingRenameAlert = false
    @State private var isShowingChangeAuthorAlert = false
    @State private var isShowingChapterRenameAlert = false
    @State private var isShowingNewChapterSheet = false
    @State private var tempAuthor = ""
    @State private var tempBookName = ""
    @State private var tempChapterTitle = ""
    @State private var newChapterMode: ChapterMode = .normal
    @State private var newChapterTitleInput = ""

    @Environment(\.editMode) private var editMode

    private let sidebarMinWidth: CGFloat = 220

    private var bookNameBinding: Binding<String> {
        Binding(get: { document.bookData.bookName },
                set: { document.bookData.bookName = $0 })
    }

    var body: some View {
        layoutContent
            .onAppear {
                if selectedChapterID == nil, let first = document.bookData.chapters.first {
                    selectedChapterID = first.id
                }
                if let url = fileURL {
                    let fn = url.deletingPathExtension().lastPathComponent
                    let isDefault = fn == "未命名書籍" || fn == "未命名书籍"
                    let nameFromContent = document.bookData.bookName
                    let contentIsDefault = nameFromContent == "未命名書籍" || nameFromContent == "未命名书籍"

                    if !contentIsDefault && isDefault {
                        let newURL = url.deletingLastPathComponent().appendingPathComponent("\(nameFromContent).md")
                        DispatchQueue.global(qos: .utility).async { try? FileManager.default.moveItem(at: url, to: newURL) }
                    } else if contentIsDefault {
                        document.bookData.bookName = fn
                    } else if nameFromContent != fn {
                        document.bookData.bookName = nameFromContent
                        let newURL = url.deletingLastPathComponent().appendingPathComponent("\(nameFromContent).md")
                        DispatchQueue.global(qos: .utility).async { try? FileManager.default.moveItem(at: url, to: newURL) }
                    }

                    // 清理 DocumentGroup 因 .plainText readableContentType 产生的 .txt 缓存
                    let dir = url.deletingLastPathComponent()
                    DispatchQueue.global(qos: .utility).async {
                        do {
                            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                            for f in files where f.pathExtension == "txt" {
                                let md = f.deletingPathExtension().appendingPathExtension("md")
                                if FileManager.default.fileExists(atPath: md.path) {
                                    try? FileManager.default.removeItem(at: f)
                                }
                            }
                        } catch {}
                    }
                }
                if document.bookData.bookName == "未命名书籍" || document.bookData.bookName == "未命名書籍" {
                    isShowingBookInfoOnStart = true
                }
            }
            .onChange(of: fileURL) { _, newURL in
                guard let url = newURL else { return }
                let fn = url.deletingPathExtension().lastPathComponent
                if document.bookData.bookName != fn && document.bookData.bookName != "未命名書籍" && document.bookData.bookName != "未命名书籍" {
                    document.bookData.bookName = fn
                }
            }
            .onChange(of: selectedChapterID) { _, _ in renamingChapterID = nil }
            .sheet(isPresented: $isShowingBookInfoOnStart) {
                NewBookInfoSheet(isPresented: $isShowingBookInfoOnStart) { name, author in
                    document.bookData.bookName = name; document.bookData.author = author
                }
            }
            .alert("重命名", isPresented: $isShowingRenameAlert) {
                TextField("请输入书名", text: $tempBookName)
                Button("取消", role: .cancel) {}
                Button("确定") {
                    let n = tempBookName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty, n != document.bookData.bookName else { return }
                    let old = fileURL
                    document.bookData.bookName = n
                    if let old {
                        let new = old.deletingLastPathComponent().appendingPathComponent("\(n).md")
                        DispatchQueue.global(qos: .utility).async { try? FileManager.default.moveItem(at: old, to: new) }
                    }
                }
            }
            .alert("修改作者", isPresented: $isShowingChangeAuthorAlert) {
                TextField("请输入作者名", text: $tempAuthor)
                Button("取消", role: .cancel) {}
                Button("确定") {
                    let t = tempAuthor.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { document.bookData.author = t }
                }
            }
            .alert("重命名章节", isPresented: $isShowingChapterRenameAlert) {
                TextField("请输入章节标题", text: $tempChapterTitle)
                Button("取消", role: .cancel) { renamingChapterID = nil }
                Button("确定") {
                    let t = tempChapterTitle.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty, let id = renamingChapterID,
                       let idx = document.bookData.chapters.firstIndex(where: { $0.id == id }) {
                        document.bookData.chapters[idx].title = t
                    }
                    renamingChapterID = nil
                }
            }
            .sheet(isPresented: $isShowingNewChapterSheet) {
                NewChapterSheet(mode: $newChapterMode, title: $newChapterTitleInput) {
                    let t = newChapterTitleInput.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { document.bookData.addChapter(title: t, mode: newChapterMode) }
                    isShowingNewChapterSheet = false
                }
            }
            .fileExporter(
                isPresented: $isShowingPublish,
                document: EPUBExportDocument(bookData: document.bookData),
                contentType: UTType.writonEpub,
                defaultFilename: "\(document.bookData.bookName).epub"
            ) { _ in }
    }

    // MARK: - 布局

    @ViewBuilder
    private var layoutContent: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if editMode?.wrappedValue.isEditing == true {
                // iPad 编辑模式 → 切回 iPhone 样式（NavigationStack）
                iPhoneLayout
            } else {
                iPadLayout
            }
        } else {
            iPhoneLayout
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            chapterSidebar(padMode: true)
                .navigationSplitViewColumnWidth(min: sidebarMinWidth, ideal: 260, max: 360)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { EditButton() } }
        } detail: {
            chapterDetail
                .navigationTitle(bookNameBinding)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { titleMenuOnly }
        }
        .documentHeader(from: fileURL)
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            chapterSidebar(padMode: false)
                .navigationTitle(bookNameBinding)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: UUID.self) { chapterID in
                    if let idx = document.bookData.chapters.firstIndex(where: { $0.id == chapterID }) {
                        ChapterEditorView(chapter: Binding(
                            get: { document.bookData.chapters[idx] },
                            set: { document.bookData.chapters[idx] = $0 }
                        ))
                        .navigationTitle(document.bookData.chapters[idx].title)
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }
                .toolbar { toolbarContent }
        }
        .documentHeader(from: fileURL)
    }

    // MARK: - 工具栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarTitleMenu {
            Button { tempBookName = document.bookData.bookName; isShowingRenameAlert = true }
                label: { Label("重命名", systemImage: "pencil") }
            Button { tempAuthor = document.bookData.author; isShowingChangeAuthorAlert = true }
                label: { Label("修改作者", systemImage: "person") }
            Button { isShowingPublish = true }
                label: { Label("发布为 EPUB", systemImage: "book") }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
        }
    }

    @ToolbarContentBuilder
    private var titleMenuOnly: some ToolbarContent {
        ToolbarTitleMenu {
            Button { tempBookName = document.bookData.bookName; isShowingRenameAlert = true }
                label: { Label("重命名", systemImage: "pencil") }
            Button { tempAuthor = document.bookData.author; isShowingChangeAuthorAlert = true }
                label: { Label("修改作者", systemImage: "person") }
            Button { isShowingPublish = true }
                label: { Label("发布为 EPUB", systemImage: "book") }
        }
    }

    // MARK: - 章节操作

    private func deleteChapters(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) { document.bookData.removeChapter(at: i) }
        if let sel = selectedChapterID,
           !document.bookData.chapters.contains(where: { $0.id == sel }) {
            selectedChapterID = document.bookData.chapters.first?.id
        }
    }

    private func moveChapters(from src: IndexSet, to dst: Int) {
        document.bookData.chapters.move(fromOffsets: src, toOffset: dst)
        document.bookData.renumberChapters()
    }

    // MARK: - 侧边栏

    private func chapterSidebar(padMode: Bool) -> some View {
        List {
            Section {
                ForEach($document.bookData.chapters) { $chapter in
                    if padMode {
                        Button { selectedChapterID = chapter.id } label: {
                            chapterLabel(chapter)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            selectedChapterID == chapter.id
                            ? RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.12))
                                .padding(.horizontal, 6)
                            : nil
                        )
                        .swipeActions(edge: .trailing) { swipeButtons(for: chapter) }
                    } else {
                        NavigationLink(value: chapter.id) { chapterLabel(chapter) }
                            .swipeActions(edge: .trailing) { swipeButtons(for: chapter) }
                    }
                }
                .onDelete(perform: deleteChapters)
                .onMove(perform: moveChapters)

                Button {
                    newChapterMode = .normal; newChapterTitleInput = ""; isShowingNewChapterSheet = true
                } label: { Label("添加章节", systemImage: "plus") }
            } header: { Text("章节列表") }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func swipeButtons(for chapter: Chapter) -> some View {
        Button(role: .destructive) {
            if let i = document.bookData.chapters.firstIndex(where: { $0.id == chapter.id }) {
                document.bookData.removeChapter(at: i)
            }
        } label: { Label("删除", systemImage: "trash") }
        Button {
            renamingChapterID = chapter.id; tempChapterTitle = chapter.title; isShowingChapterRenameAlert = true
        } label: { Label("重命名", systemImage: "pencil") }.tint(.orange)
    }

    private func chapterLabel(_ chapter: Chapter) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(modeAndNumberText(chapter)).font(.caption2).foregroundStyle(.secondary)
            Text(chapter.title).font(.body).lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private func modeAndNumberText(_ chapter: Chapter) -> String {
        if chapter.mode == .special {
            return "\(String(localized: "间章")) \(chapter.number)"
        }
        return String(format: String(localized: "第%lld章"), chapter.number)
    }

    // MARK: - 详情区

    @ViewBuilder
    private var chapterDetail: some View {
        if let id = selectedChapterID,
           let idx = document.bookData.chapters.firstIndex(where: { $0.id == id }) {
            ChapterEditorView(chapter: Binding(
                get: { document.bookData.chapters[idx] },
                set: { document.bookData.chapters[idx] = $0 }
            )).id(id)
        } else {
            ContentUnavailableView("选择一个章节", systemImage: "text.justify.leading",
                                   description: Text("从左侧章节列表中点击要编辑的章节"))
        }
    }
}

// MARK: - 新建章节弹窗

private struct NewChapterSheet: View {
    @Binding var mode: ChapterMode
    @Binding var title: String
    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("章节类型", selection: $mode) {
                    ForEach(ChapterMode.allCases, id: \.self) { m in Text(m.displayName).tag(m) }
                }
                TextField("章节标题", text: $title)
            }
            .navigationTitle("新建章节").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { onCreate() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if title.trimmingCharacters(in: .whitespaces).isEmpty {
                            title = mode == .special ? String(localized: "间章") + " \(mode)" : String(localized: "新章节")
                        }
                        onCreate()
                    } label: { Image(systemName: "checkmark").fontWeight(.semibold) }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    BookEditorView(document: .constant(BookDocument(bookName: "我的奇幻小说", author: "张三")), fileURL: nil)
}
