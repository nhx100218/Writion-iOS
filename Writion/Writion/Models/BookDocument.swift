/*
 Writion — 书籍创作 App
 文档模型 — FileDocument 协议实现

 支持两种文本格式：
 旧版：#...# 分隔线格式（向后兼容）
 新版：#Start#...#End# 格式（Mode 区分普通/间章）
*/

import SwiftUI
import UniformTypeIdentifiers

struct BookDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.writionBook, .plainText] }

    var bookData: BookData

    init(bookName: String = "未命名书籍", author: String = "未知作者") {
        self.bookData = BookData(bookName: bookName, author: author,
                                 chapters: [Chapter(mode: .normal, number: 1, title: "第一章", content: "")])
    }

    init(bookData: BookData) { self.bookData = bookData }

    // MARK: - Read

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8)
        else { throw CocoaError(.fileReadCorruptFile) }
        let parsed = Self.parseBook(from: text)
        if parsed.bookName.isEmpty {
            let filename = configuration.file.filename ?? "未命名书籍"
            self.bookData = BookData(bookName: filename, author: "未知作者",
                                     chapters: [Chapter(mode: .normal, number: 1, title: "第一章", content: text)])
        } else {
            self.bookData = parsed
        }
    }

    // MARK: - Write (新版格式)

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let text = Self.serializeBook(bookData)
        guard let data = text.data(using: .utf8) else { throw CocoaError(.fileWriteUnknown) }
        return FileWrapper(regularFileWithContents: data)
    }

    // MARK: ── 格式检测 ──

    private static func detectFormat(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#Start#") { return "new" }
        return "old"
    }

    // MARK: ── 统一入口 ──

    static func parseBook(from text: String) -> BookData {
        if detectFormat(text) == "new" { return parseNewFormat(text) }
        return parseOldFormat(text)
    }

    // MARK: ── 旧版解析器（向后兼容） ──

    private static let oldSeparator = "############################################################################################"
    private static let commentPrefix = "//"

    static func parseOldFormat(_ text: String) -> BookData {
        var bookName = "", author = ""
        var chapters: [Chapter] = []

        let lines = text.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count && isAllHash(lines[i]) { i += 1 } // skip opening sep
        if i < lines.count {
            let ln = lines[i].trimmingCharacters(in: .whitespaces)
            if ln.hasPrefix("Book Name: ") { bookName = String(ln.dropFirst(11)).trimmingCharacters(in: .whitespaces) }
            i += 1
        }
        while i < lines.count && isAllHash(lines[i]) { i += 1 }
        if i < lines.count {
            let ln = lines[i].trimmingCharacters(in: .whitespaces)
            if ln.hasPrefix("Author: ") { author = String(ln.dropFirst(8)).trimmingCharacters(in: .whitespaces) }
            i += 1
        }
        while i < lines.count && isAllHash(lines[i]) { i += 1 }

        while i < lines.count {
            let ln = lines[i].trimmingCharacters(in: .whitespaces)
            if ln.isEmpty { i += 1; continue }
            if ln.hasPrefix("Chapters: ") {
                let num = Int(String(ln.dropFirst(10)).trimmingCharacters(in: .whitespaces)) ?? (chapters.count + 1)
                i += 1
                if i < lines.count && isAllDash(lines[i]) { i += 1 }
                var title = "第\(num)章"
                if i < lines.count {
                    let tl = lines[i].trimmingCharacters(in: .whitespaces)
                    if tl.hasPrefix("Title: ") { title = String(tl.dropFirst(7)).trimmingCharacters(in: .whitespaces) }
                    i += 1
                }
                if i < lines.count && isAllDash(lines[i]) { i += 1 }
                if i < lines.count && lines[i].trimmingCharacters(in: .whitespaces) == "Content:" { i += 1 }
                var bodyLines: [String] = []
                while i < lines.count {
                    let cl = lines[i].trimmingCharacters(in: .whitespaces)
                    if cl.hasPrefix(commentPrefix) { i += 1; continue }
                    if isAllDash(lines[i]) || isAllHash(lines[i]) { break }
                    if cl.hasPrefix("Chapters: ") { break }
                    bodyLines.append(lines[i])
                    i += 1
                }
                let content = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                chapters.append(Chapter(mode: .normal, number: num, title: title, content: content))
            } else { i += 1 }
        }
        return BookData(bookName: bookName, author: author, chapters: chapters)
    }

    // MARK: ── 新版解析器 ──

    private static let newSectionSep = "------------"

    static func parseNewFormat(_ text: String) -> BookData {
        var bookName = "", author = ""
        var chapters: [Chapter] = []

        let lines = text.components(separatedBy: .newlines)
        var i = 0

        // skip #Start#
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t == "#Start#" { i += 1; continue }
            if !t.isEmpty && t != "#Start#" { break }
            i += 1
        }
        // Book Name:
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("Book Name: ") { bookName = String(t.dropFirst(11)).trimmingCharacters(in: .whitespaces); i += 1; break }
            i += 1
        }
        // Author:
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("Author: ") { author = String(t.dropFirst(8)).trimmingCharacters(in: .whitespaces); i += 1; break }
            i += 1
        }
        // skip to #Text_Page#
        while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces) != "#Text_Page#" { i += 1 }
        if i < lines.count { i += 1 } // skip #Text_Page#
        // skip to first ------------
        while i < lines.count && !isNewSep(lines[i]) { i += 1 }
        if i < lines.count { i += 1 } // skip first ------------

        // parse chapter blocks within #Text_Page# ... #End#
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if t == "#End#" { break }
            if t.isEmpty { i += 1; continue }

            // read Mode: Normal / Mode: Special
            var mode: ChapterMode = .normal
            if t.hasPrefix("Mode: ") {
                let m = String(t.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                mode = (m == "Special") ? .special : .normal
                i += 1
            }

            // skip to Chapters: N
            while i < lines.count {
                let ln = lines[i].trimmingCharacters(in: .whitespaces)
                if ln.hasPrefix("Chapters: ") { break }
                if ln == "#End#" { break }
                i += 1
            }
            if i >= lines.count || lines[i].trimmingCharacters(in: .whitespaces) == "#End#" { break }

            let num = Int(String(lines[i].trimmingCharacters(in: .whitespaces).dropFirst(10)).trimmingCharacters(in: .whitespaces)) ?? (chapters.filter({$0.mode==mode}).count + 1)
            i += 1

            // skip ------
            if i < lines.count && isAllDash(lines[i]) { i += 1 }

            // Title: ...
            var title = "第\(num)章"
            if i < lines.count {
                let tl = lines[i].trimmingCharacters(in: .whitespaces)
                if tl.hasPrefix("Title: ") { title = String(tl.dropFirst(7)).trimmingCharacters(in: .whitespaces) }
                i += 1
            }
            // skip ------
            if i < lines.count && isAllDash(lines[i]) { i += 1 }

            // Content:
            if i < lines.count && lines[i].trimmingCharacters(in: .whitespaces) == "Content:" { i += 1 }

            // read body until ------ or ------------ or #End#
            var bodyLines: [String] = []
            while i < lines.count {
                let cl = lines[i].trimmingCharacters(in: .whitespaces)
                if cl.hasPrefix(commentPrefix) { i += 1; continue }
                if isNewSep(lines[i]) || cl == "#End#" || (isAllDash(lines[i]) && i+1 < lines.count && (lines[i+1].trimmingCharacters(in: .whitespaces).hasPrefix("Mode:") || lines[i+1].trimmingCharacters(in: .whitespaces) == "#End#" || isNewSep(lines[i+1]))) { break }
                if isAllDash(lines[i]) && i+1 < lines.count && lines[i+1].trimmingCharacters(in: .whitespaces).hasPrefix("Chapters:") { break }
                if isAllDash(lines[i]) { break }
                bodyLines.append(lines[i])
                i += 1
            }
            let content = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            chapters.append(Chapter(mode: mode, number: num, title: title, content: content))

            // skip trailing ------
            if i < lines.count && isAllDash(lines[i]) { i += 1 }
        }
        return BookData(bookName: bookName, author: author, chapters: chapters)
    }

    // MARK: ── 新版序列化 ──

    static func serializeBook(_ bookData: BookData) -> String {
        var lines: [String] = []
        lines.append("#Start#")
        lines.append("Book Name: \(bookData.bookName)")
        lines.append("Author: \(bookData.author)")
        lines.append("#Text_Page#")
        lines.append(newSectionSep)

        for chapter in bookData.chapters {
            lines.append("Mode: \(chapter.mode.rawValue)")
            lines.append("Chapters: \(chapter.number)")
            lines.append("------")
            lines.append("Title: \(chapter.title)")
            lines.append("------")
            lines.append("Content:")
            if !chapter.content.isEmpty { lines.append(chapter.content) }
            lines.append("------")
        }
        lines.append(newSectionSep)
        lines.append("#End#")
        return lines.joined(separator: "\n")
    }

    // MARK: ── 辅助 ──

    private static func isAllHash(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return !t.isEmpty && t.allSatisfy({ $0 == "#" }) && t.count > 10
    }
    private static func isAllDash(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return !t.isEmpty && t.allSatisfy({ $0 == "-" }) && t.count >= 6
    }
    private static func isNewSep(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces) == newSectionSep
    }
}
