/*
 Writion — 书籍创作 App
 新建书籍信息输入弹窗

 用户点击"新建书籍"后，此弹窗要求输入书名和作者，
 确认后会创建一本新书并进入编辑界面
*/

import SwiftUI

/// 新建书籍信息弹窗
/// 用于收集书名和作者名，然后创建对应的 BookDocument
struct NewBookInfoSheet: View {
    // MARK: - 绑定与回调

    /// 弹窗是否显示
    @Binding var isPresented: Bool
    /// 用户输入的书名
    @State private var bookName: String = ""
    /// 用户输入的作者名
    @State private var author: String = ""
    /// 创建完成后的回调，传递书名和作者
    let onCreate: (String, String) -> Void

    // MARK: - 聚焦状态

    /// 控制书名输入框的焦点，弹窗出现时自动聚焦
    @FocusState private var isBookNameFocused: Bool

    // MARK: - 私有常量

    /// 弹窗最大宽度（iPad 时限制宽度）
    private let maxSheetWidth: CGFloat = 480

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - iOS 布局

    private var iOSLayout: some View {
        NavigationStack {
            formContent
                .navigationTitle("新建书籍")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // 仅保留勾号确认按钮，下方拖拽栏可关闭弹窗
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            createBook()
                        } label: {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                        .disabled(bookName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isBookNameFocused = true
            }
        }
    }

    // MARK: - macOS 布局

    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // 标题栏
            Text("新建书籍")
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 16)

            formContent
                .padding(.horizontal, 30)

            // 底部按钮
            HStack {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("创建") {
                    createBook()
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(bookName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
        .frame(width: 420)
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - 表单内容

    private var formContent: some View {
        Form {
            // 书名输入区
            Section {
                TextField("请输入书名", text: $bookName)
                    .focused($isBookNameFocused)
                    .onSubmit {
                        // 在书名输入框按回车时自动跳转到作者输入框
                        // （iOS 上 TextField 的 onSubmit 行为）
                        if !bookName.trimmingCharacters(in: .whitespaces).isEmpty {
                            createBook()
                        }
                    }
            } header: {
                Label("书名", systemImage: "book")
            }

            // 作者输入区
            Section {
                TextField("请输入作者名", text: $author)
            } header: {
                Label("作者", systemImage: "person")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - 创建书籍

    /// 校验输入并回调创建
    private func createBook() {
        let trimmedName = bookName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespaces)
        let finalAuthor = trimmedAuthor.isEmpty ? "未知作者" : trimmedAuthor

        isPresented = false
        onCreate(trimmedName, finalAuthor)
    }
}

#Preview {
    NewBookInfoSheet(isPresented: .constant(true)) { name, author in
        print("创建书籍: \(name), 作者: \(author)")
    }
}
