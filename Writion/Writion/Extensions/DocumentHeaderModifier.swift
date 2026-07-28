/*
 Writion — 书籍创作 App
 缩略图 + 分享按钮

 DocumentGroup 不使用 UIDocumentViewController，因此需手动
 设置 UINavigationItem.documentProperties。关键：须设置到
 当前实际可见的 topViewController.navigationItem 上。
*/
import SwiftUI
import UIKit

struct DocumentHeaderModifier: ViewModifier {
    let fileURL: URL?

    func body(content: Content) -> some View {
        content
            .onAppear { apply() }
            .onChange(of: fileURL?.absoluteString) { _, _ in apply() }
    }

    private func apply() {
        guard let fileURL else { return }
        // 等导航栏完全就绪
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard let keyWindow = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first
            else { return }
            applyToWindow(keyWindow, url: fileURL)
        }
    }

    /// 从 keyWindow 下方遍历所有 VC，为每个可见的 topViewController 设置 documentProperties
    private func applyToWindow(_ window: UIWindow, url: URL) {
        guard let root = window.rootViewController else { return }
        visit(root, url: url)
    }

    /// 深度优先遍历，为每个导航控制器的 topViewController 设置
    private func visit(_ vc: UIViewController, url: URL) {
        if let nav = vc as? UINavigationController {
            // 这是关键: 设置 topViewController（即 SwiftUI 的 UIHostingController）的 navigationItem
            if let top = nav.topViewController {
                let props = UIDocumentProperties(url: url)
                props.activityViewControllerProvider = {
                    UIActivityViewController(activityItems: [url], applicationActivities: nil)
                }
                top.navigationItem.documentProperties = props
            }
            // 继续遍历 pushed VC
            for pushed in nav.viewControllers {
                visit(pushed, url: url)
            }
        }
        if let split = vc as? UISplitViewController {
            for col in split.viewControllers { visit(col, url: url) }
        }
        for child in vc.children { visit(child, url: url) }
        if let presented = vc.presentedViewController { visit(presented, url: url) }
    }
}

extension View {
    func documentHeader(from fileURL: URL?) -> some View {
        modifier(DocumentHeaderModifier(fileURL: fileURL))
    }
}
