/*
 Writion — 书籍创作 App
 EPUB 3 导出工具
*/

import Foundation
import Compression

enum EPUBExporter {
    static func export(bookData: BookData) -> Data? {
        let bookName = bookData.bookName
        let author = bookData.author
        let uuid = UUID().uuidString

        var entries: [ZIPEntry] = []

        // 1. mimetype（无压缩，无额外字段，EPUB 校验必须第一个）
        entries.append(ZIPEntry(
            path: "mimetype",
            data: "application/epub+zip".data(using: .utf8)!,
            compress: false,
            mimetypeEntry: true
        ))

        // 2. META-INF/container.xml
        let container = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
        """
        entries.append(ZIPEntry(path: "META-INF/container.xml", data: container.data(using: .utf8)!, compress: true))

        // 3. 章节 XHTML
        for ch in bookData.chapters {
            let fn = "chapter_\(ch.number).xhtml"
            let safeTitle = escapeXML(ch.title)
            let bodyHTML = simpleMarkdownToHTML(ch.content)
            let xhtml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
            <head><title>\(safeTitle)</title></head>
            <body><h1>\(safeTitle)</h1>\(bodyHTML)</body>
            </html>
            """
            entries.append(ZIPEntry(path: "OEBPS/\(fn)", data: xhtml.data(using: .utf8)!, compress: true))
        }

        // 4. content.opf
        var manifest = ""
        var spine = ""
        for ch in bookData.chapters {
            let fn = "chapter_\(ch.number).xhtml"
            manifest += "<item id=\"\(fn)\" href=\"\(fn)\" media-type=\"application/xhtml+xml\"/>\n"
            spine += "<itemref idref=\"\(fn)\"/>\n"
        }
        let opf = """
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="3.0">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>\(escapeXML(bookName))</dc:title>
            <dc:creator>\(escapeXML(author))</dc:creator>
            <dc:language>zh-CN</dc:language>
            <dc:identifier id="BookID">urn:uuid:\(uuid)</dc:identifier>
          </metadata>
          <manifest>
            \(manifest)
          </manifest>
          <spine>
            \(spine)
          </spine>
        </package>
        """
        entries.append(ZIPEntry(path: "OEBPS/content.opf", data: opf.data(using: .utf8)!, compress: true))

        return ZIPWriter.write(entries)
    }

    private static func escapeXML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "'", with: "&apos;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func simpleMarkdownToHTML(_ md: String) -> String {
        guard !md.isEmpty else { return "" }
        var html = md
        // **bold**
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>",
                                         options: .regularExpression)
        // *italic*
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>",
                                         options: .regularExpression)
        // headers
        for level in (1...6).reversed() {
            let hashes = String(repeating: "#", count: level)
            html = html.replacingOccurrences(of: "(?m)^\(hashes) (.+)$", with: "<h\(level)>$1</h\(level)>",
                                             options: .regularExpression)
        }
        // paragraphs (double newline → <p>)
        let parts = html.components(separatedBy: "\n\n")
        html = parts.map { para in
            let t = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return "" }
            if t.hasPrefix("<h") || t.hasPrefix("<strong>") || t.hasPrefix("<em>") || t.hasPrefix("<p>") { return t }
            return "<p>\(t.replacingOccurrences(of: "\n", with: "<br/>"))</p>"
        }.joined(separator: "\n")
        return html
    }
}

// MARK: - ZIP 写入器

private struct ZIPEntry {
    let path: String
    let data: Data
    let compress: Bool
    var mimetypeEntry: Bool = false
}

private enum ZIPWriter {
    static func write(_ entries: [ZIPEntry]) -> Data? {
        var body = Data()
        var centralDir = Data()
        var offset: UInt32 = 0

        for entry in entries {
            let pathBytes = entry.path.data(using: .utf8)!
            let crc = crc32(entry.data)
            var method: UInt16 = 0
            var toWrite = entry.data

            if entry.compress {
                if let d = deflate(entry.data), d.count < entry.data.count {
                    toWrite = d
                    method = 8
                }
            }

            let verNeeded: UInt16 = entry.mimetypeEntry ? 10 : 20

            var local = Data()
            local.append(sig(0x04034b50))
            local.append(u16Le(verNeeded))
            local.append(u16Le(0))    // flags
            local.append(u16Le(method))
            local.append(u16Le(0))    // mtime
            local.append(u16Le(0))    // mdate
            local.append(u32Le(crc))
            local.append(u32Le(UInt32(toWrite.count)))
            local.append(u32Le(UInt32(entry.data.count)))
            local.append(u16Le(UInt16(pathBytes.count)))
            local.append(u16Le(0))    // extra length — mimetype 为 0

            body.append(local)
            body.append(pathBytes)
            body.append(toWrite)

            var cd = Data()
            cd.append(sig(0x02014b50))
            cd.append(u16Le(20))       // version made by
            cd.append(u16Le(verNeeded))
            cd.append(u16Le(0))        // flags
            cd.append(u16Le(method))
            cd.append(u16Le(0))
            cd.append(u16Le(0))
            cd.append(u32Le(crc))
            cd.append(u32Le(UInt32(toWrite.count)))
            cd.append(u32Le(UInt32(entry.data.count)))
            cd.append(u16Le(UInt16(pathBytes.count)))
            cd.append(u16Le(0))        // extra len
            cd.append(u16Le(0))        // comment len
            cd.append(u16Le(0))
            cd.append(u16Le(0))
            cd.append(u32Le(0))
            cd.append(u32Le(offset))
            centralDir.append(cd)
            centralDir.append(pathBytes)

            offset += UInt32(local.count + pathBytes.count + toWrite.count)
        }

        let cdStart = UInt32(body.count)
        body.append(centralDir)

        var eocd = Data()
        eocd.append(sig(0x06054b50))
        eocd.append(u16Le(0))
        eocd.append(u16Le(0))
        eocd.append(u16Le(UInt16(entries.count)))
        eocd.append(u16Le(UInt16(entries.count)))
        eocd.append(u32Le(UInt32(centralDir.count)))
        eocd.append(u32Le(cdStart))
        eocd.append(u16Le(0))
        body.append(eocd)

        return body
    }

    private static func deflate(_ data: Data) -> Data? {
        let srcSize = data.count
        var dst = Data(count: srcSize + 64)
        let written = dst.withUnsafeMutableBytes { dstBuf -> Int in
            data.withUnsafeBytes { src in
                compression_encode_buffer(
                    dstBuf.bindMemory(to: UInt8.self).baseAddress!, dstBuf.count,
                    src.bindMemory(to: UInt8.self).baseAddress!, srcSize,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard written > 6 else { return nil }
        return dst.prefix(written).dropFirst(2).dropLast(4)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in data {
            c = (c >> 8) ^ crcTable[Int((c ^ UInt32(b)) & 0xFF)]
        }
        return c ^ 0xFFFF_FFFF
    }

    private static let crcTable: [UInt32] = {
        var t = [UInt32](repeating: 0, count: 256)
        for n in 0..<256 {
            var c = UInt32(n)
            for _ in 0..<8 { c = (c & 1 != 0) ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1) }
            t[n] = c
        }
        return t
    }()

    private static func sig(_ v: UInt32) -> Data {
        var val = v
        return Data(bytes: &val, count: 4)
    }
    private static func u16Le(_ v: UInt16) -> Data {
        var val = v.littleEndian; return Data(bytes: &val, count: 2)
    }
    private static func u32Le(_ v: UInt32) -> Data {
        var val = v.littleEndian; return Data(bytes: &val, count: 4)
    }
}
