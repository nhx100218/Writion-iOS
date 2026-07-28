/*
 Writion — 书籍创作 App
 定义应用专属的文档类型（Uniform Type Identifier）

 文件扩展名为 .md，内容为 Markdown 格式，遵循 Writion 自定义的书籍结构
*/

import UniformTypeIdentifiers

extension UTType {
    /// Writion 书籍文档类型
    /// - 唯一标识符: com.novawisesyndicate.writion-book
    /// - 文件扩展名: md（Markdown 格式）
    /// - 遵循父类型: public.plain-text（纯文本）
    static var writionBook: UTType {
        UTType(exportedAs: "com.novawisesyndicate.writion-book")
    }

    /// EPUB 电子书（系统内置 UTI）
    static var writonEpub: UTType {
        UTType(filenameExtension: "epub") ?? UTType("org.idpf.epub-container")!
    }
}
