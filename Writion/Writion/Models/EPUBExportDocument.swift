/*
 Writion — 书籍创作 App
 EPUB 导出文档包装

 用于 fileExporter 导出 EPUB 文件
 仅写入，不支持读取
*/

import SwiftUI
import UniformTypeIdentifiers

/// 仅用于导出的 EPUB 文档包装
struct EPUBExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType.writonEpub] }

    var epubData: Data

    init(bookData: BookData) {
        self.epubData = EPUBExporter.export(bookData: bookData) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: epubData)
    }
}
