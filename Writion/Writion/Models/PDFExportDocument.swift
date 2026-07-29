/*
 Writion — 书籍创作 App
 PDF 导出文档包装
*/

import SwiftUI
import UniformTypeIdentifiers

struct PDFExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    let pdfData: Data

    init(bookData: BookData) {
        self.pdfData = PDFExporter.export(bookData: bookData) ?? Data()
    }
    init(configuration: ReadConfiguration) throws { throw CocoaError(.fileReadUnsupportedScheme) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: pdfData)
    }
}
