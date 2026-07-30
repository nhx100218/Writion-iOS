import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ImageExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }
    let pngData: Data
    init(bookData: BookData) {
        let text = "# \(bookData.bookName)\n\n\(bookData.author)\n\n" +
            bookData.chapters.map { "## \($0.title)\n\($0.content)" }.joined(separator: "\n\n")
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: CGFloat(text.count / 40 + 40) * 20))
        self.pngData = renderer.pngData { _ in
            let para = NSMutableParagraphStyle(); para.lineSpacing = 4
            (text as NSString).draw(in: CGRect(x: 20, y: 20, width: 760, height: CGFloat.greatestFiniteMagnitude),
                                    withAttributes: [.font: UIFont.systemFont(ofSize: 14), .paragraphStyle: para])
        }
        #else
        pngData = Data()
        #endif
    }
    init(configuration: ReadConfiguration) throws { throw CocoaError(.fileReadUnsupportedScheme) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: pngData) }
}
