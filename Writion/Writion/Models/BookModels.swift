/*
 Writion — 书籍创作 App
 数据模型：ChapterMode（章节类型）+ Chapter + BookData
*/

import Foundation

// MARK: - 章节模式

enum ChapterMode: String, Codable, CaseIterable, Hashable {
    case normal = "Normal"   // 普通大章节
    case special = "Special" // 间章

    var displayName: String {
        switch self {
        case .normal: return String(localized: "普通章节")
        case .special: return String(localized: "间章")
        }
    }
}

// MARK: - 章节

struct Chapter: Identifiable, Hashable, Codable {
    var id = UUID()
    /// 章节模式（normal 普通 / special 间章）
    var mode: ChapterMode
    /// 同类型章节中的序号（独立编号）
    var number: Int
    /// 章节标题
    var title: String
    /// 章节正文（Markdown）
    var content: String

    init(id: UUID = UUID(), mode: ChapterMode = .normal, number: Int, title: String, content: String = "") {
        self.id = id
        self.mode = mode
        self.number = number
        self.title = title
        self.content = content
    }
}

// MARK: - 书籍数据

struct BookData {
    var bookName: String
    var author: String
    var chapters: [Chapter]

    init(bookName: String = "", author: String = "", chapters: [Chapter] = []) {
        self.bookName = bookName
        self.author = author
        self.chapters = chapters
    }

    // MARK: - 章节管理

    /// 添加新章节，自动计算同模式下序号
    mutating func addChapter(title: String, mode: ChapterMode = .normal, at index: Int? = nil) {
        let sameModeCount = chapters.filter { $0.mode == mode }.count
        let number = sameModeCount + 1
        let chapter = Chapter(mode: mode, number: number, title: title, content: "")
        if let i = index {
            chapters.insert(chapter, at: i)
        } else {
            chapters.append(chapter)
        }
        renumberByMode(mode)
    }

    /// 删除指定索引的章节，并重新编号同模式章节
    mutating func removeChapter(at index: Int) {
        guard index < chapters.count else { return }
        let mode = chapters[index].mode
        chapters.remove(at: index)
        renumberByMode(mode)
    }

    /// 重新计算指定模式所有章节的序号
    mutating func renumberByMode(_ mode: ChapterMode) {
        var counter = 1
        for i in chapters.indices where chapters[i].mode == mode {
            chapters[i].number = counter
            counter += 1
        }
    }

    /// 全局重新编号（旧版兼容）
    mutating func renumberChapters() {
        var normalCount = 1
        var specialCount = 1
        for i in chapters.indices {
            switch chapters[i].mode {
            case .normal:
                chapters[i].number = normalCount; normalCount += 1
            case .special:
                chapters[i].number = specialCount; specialCount += 1
            }
        }
    }
}
