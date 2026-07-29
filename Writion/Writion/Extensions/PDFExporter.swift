/*
 Writion — 书籍创作 App
 PDF 导出 — UIKit 原生 PDF 渲染
*/

import UIKit

enum PDFExporter {
    static func export(bookData: BookData) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { ctx in
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headingFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let margin: CGFloat = 56

            // Cover page
            ctx.beginPage()
            drawCentered(bookData.bookName, font: titleFont, y: pageRect.midY - 20, in: pageRect, margin: margin)
            drawCentered(bookData.author, font: bodyFont, y: pageRect.midY + 20, in: pageRect, margin: margin)

            for chapter in bookData.chapters {
                ctx.beginPage()
                var y: CGFloat = margin
                let numText = chapter.mode == .special
                    ? "间章 \(chapter.number)"
                    : "第\(chapter.number)章"
                y = drawSimple("\(numText)  \(chapter.title)", font: headingFont, y: y, in: pageRect, margin: margin)
                y += 16

                for line in chapter.content.components(separatedBy: "\n") {
                    if y > pageRect.height - margin - 20 {
                        ctx.beginPage()
                        y = margin
                    }
                    y = drawSimple(line.isEmpty ? " " : line, font: bodyFont, y: y, in: pageRect, margin: margin)
                    y += 4
                }
            }
        }
    }

    private static func drawCentered(_ text: String, font: UIFont, y: CGFloat, in rect: CGRect, margin: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attrs)
        let x = max(margin, (rect.width - size.width) / 2)
        (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }

    private static func drawSimple(_ text: String, font: UIFont, y: CGFloat, in rect: CGRect, margin: CGFloat) -> CGFloat {
        let maxWidth = rect.width - margin * 2
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: maxWidth, height: size.height), withAttributes: attrs)
        return y + size.height
    }
}
