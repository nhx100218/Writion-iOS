import SwiftUI
import UniformTypeIdentifiers

struct TXTExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    let text: String
    init(bookData: BookData) { self.text = bookData.chapters.map { "\($0.title)\n\($0.content)" }.joined(separator: "\n\n") }
    init(configuration: ReadConfiguration) throws { throw CocoaError(.fileReadUnsupportedScheme) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: text.data(using: .utf8)!) }
}
