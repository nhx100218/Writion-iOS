/*
 Writion — 书籍创作 App
 EPUB 导出工具

 生成符合 EPUB 3 规范的 .epub 文件
 使用内置 ZIP 编码器（无需外部依赖）
*/

import Foundation
import Compression

// MARK: - EPUB 导出

enum EPUBExporter {
    static func export(bookData: BookData) -> Data? {
        let bookName = bookData.bookName
        let author = bookData.author
        let uuid = UUID().uuidString

        // 收集所有文件条目
        var entries: [(path: String, data: Data, compressed: Bool)] = []

        // 1. mimetype（无压缩，必须第一个）
        entries.append(("mimetype", "application/epub+zip".data(using: .utf8)!, false))

        // 2. META-INF/container.xml
        let containerXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
        """
        entries.append(("META-INF/container.xml", containerXML.data(using: .utf8)!, true))

        // 3. 章节 XHTML
        for chapter in bookData.chapters {
            let filename = "OEBPS/chapter_\(chapter.number).xhtml"
            let safeTitle = escapeXML(chapter.title)
            let bodyHTML = markdownToHTML(chapter.content)
            let xhtml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
            <head><title>\(safeTitle)</title></head>
            <body><h1>\(safeTitle)</h1>\(bodyHTML)</body>
            </html>
            """
            entries.append((filename, xhtml.data(using: .utf8)!, true))
        }

        // 4. content.opf
        var manifestItems = ""
        var spineItems = ""
        for chapter in bookData.chapters {
            let fn = "chapter_\(chapter.number).xhtml"
            manifestItems += "<item id=\"\(fn)\" href=\"\(fn)\" media-type=\"application/xhtml+xml\"/>\n"
            spineItems += "<itemref idref=\"\(fn)\"/>\n"
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
          <manifest>\(manifestItems)</manifest>
          <spine>\(spineItems)</spine>
        </package>
        """
        entries.append(("OEBPS/content.opf", opf.data(using: .utf8)!, true))

        // 打包为 ZIP
        return ZIPWriter.create(from: entries)
    }

    private static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func markdownToHTML(_ md: String) -> String {
        var html = md
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { p in
            let t = p.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return "" }
            if t.hasPrefix("<h") { return t }
            return "<p>\(t.replacingOccurrences(of: "\n", with: "<br/>"))</p>"
        }.joined(separator: "\n")
        return html
    }
}

// MARK: - 最小 ZIP 写入器

private enum ZIPWriter {
    /// 创建 ZIP 数据
    static func create(from entries: [(path: String, data: Data, compressed: Bool)]) -> Data? {
        var result = Data()
        var centralDir = Data()
        var offset: UInt32 = 0

        for (path, rawData, shouldCompress) in entries {
            let pathData = path.data(using: .utf8)!
            let crc = crc32(rawData)

            let (compressed, method): (Data, UInt16) = {
                if shouldCompress, let deflated = deflate(rawData), deflated.count < rawData.count {
                    return (deflated, 8) // DEFLATE
                }
                return (rawData, 0) // stored
            }()

            // 本地文件头
            var localHeader = Data()
            localHeader.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // signature
            localHeader.append(uint16(20)) // version needed
            localHeader.append(uint16(0))  // flags
            localHeader.append(uint16(method))
            localHeader.append(uint16(0))  // mod time
            localHeader.append(uint16(0))  // mod date
            localHeader.append(uint32(crc))
            localHeader.append(uint32(UInt32(compressed.count)))
            localHeader.append(uint32(UInt32(rawData.count)))
            localHeader.append(uint16(UInt16(pathData.count)))
            localHeader.append(uint16(0))  // extra field length
            localHeader.append(pathData)

            result.append(localHeader)
            result.append(compressed)

            // 中央目录条目
            var cdEntry = Data()
            cdEntry.append(contentsOf: [0x50, 0x4B, 0x01, 0x02]) // signature
            cdEntry.append(uint16(20)) // version made by
            cdEntry.append(uint16(20)) // version needed
            cdEntry.append(uint16(0))  // flags
            cdEntry.append(uint16(method))
            cdEntry.append(uint16(0))  // mod time
            cdEntry.append(uint16(0))  // mod date
            cdEntry.append(uint32(crc))
            cdEntry.append(uint32(UInt32(compressed.count)))
            cdEntry.append(uint32(UInt32(rawData.count)))
            cdEntry.append(uint16(UInt16(pathData.count)))
            cdEntry.append(uint16(0))  // extra field length
            cdEntry.append(uint16(0))  // file comment length
            cdEntry.append(uint16(0))  // disk number start
            cdEntry.append(uint16(0))  // internal file attributes
            cdEntry.append(uint32(0))  // external file attributes
            cdEntry.append(uint32(offset))
            cdEntry.append(pathData)

            centralDir.append(cdEntry)
            offset += UInt32(localHeader.count + compressed.count)
        }

        let cdOffset = UInt32(result.count)
        result.append(centralDir)

        // 中央目录结束记录
        var eocd = Data()
        eocd.append(contentsOf: [0x50, 0x4B, 0x05, 0x06]) // signature
        eocd.append(uint16(0))  // disk number
        eocd.append(uint16(0))  // disk with central dir
        eocd.append(uint16(UInt16(entries.count)))
        eocd.append(uint16(UInt16(entries.count)))
        eocd.append(uint32(UInt32(centralDir.count)))
        eocd.append(uint32(cdOffset))
        eocd.append(uint16(0))  // comment length
        result.append(eocd)

        return result
    }

    // MARK: - DEFLATE 压缩
    private static func deflate(_ data: Data) -> Data? {
        let srcSize = data.count
        let dstSize = srcSize + 64
        var dst = Data(count: dstSize)
        let result = data.withUnsafeBytes { srcPtr in
            dst.withUnsafeMutableBytes { dstPtr in
                compression_encode_buffer(
                    dstPtr.bindMemory(to: UInt8.self).baseAddress!, dstSize,
                    srcPtr.bindMemory(to: UInt8.self).baseAddress!, srcSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard result > 0 else { return nil }
        // 去掉 2 字节 zlib 头 + 4 字节 Adler-32 校验和尾部，得到原始 DEFLATE 流
        if result > 6 {
            return dst.prefix(result).dropFirst(2).dropLast(4)
        }
        return dst.prefix(result)
    }

    // MARK: - CRC32
    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        let table = crc32Table
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[idx]
        }
        return crc ^ 0xFFFF_FFFF
    }

    private static let crc32Table: [UInt32] = {
        var table = [UInt32](repeating: 0, count: 256)
        for n in 0..<256 {
            var c = UInt32(n)
            for _ in 0..<8 {
                if (c & 1) != 0 { c = 0xEDB8_8320 ^ (c >> 1) }
                else { c >>= 1 }
            }
            table[n] = c
        }
        return table
    }()

    // MARK: - 辅助编码
    private static func uint16(_ v: UInt16) -> Data {
        var val = v.littleEndian
        return Data(bytes: &val, count: 2)
    }
    private static func uint32(_ v: UInt32) -> Data {
        var val = v.littleEndian
        return Data(bytes: &val, count: 4)
    }
}
