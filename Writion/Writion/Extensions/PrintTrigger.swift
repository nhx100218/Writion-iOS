#if os(iOS)
import SwiftUI
import UIKit

struct PrintTrigger: UIViewRepresentable {
    @Binding var isPresented: Bool
    let bookData: BookData
    let bookName: String

    func makeUIView(context: Context) -> PrintHostView {
        PrintHostView()
    }

    func updateUIView(_ uiView: PrintHostView, context: Context) {
        if isPresented {
            isPresented = false
            let text = "# \(bookName)\n\n" +
                bookData.chapters.map { "## \($0.title)\n\($0.content)" }.joined(separator: "\n\n")
            let formatter = UISimpleTextPrintFormatter(text: text)
            formatter.font = .systemFont(ofSize: 14)
            let controller = UIPrintInteractionController.shared
            controller.printFormatter = formatter
            controller.present(animated: true)
        }
    }
}

final class PrintHostView: UIView {
    override init(frame: CGRect) { super.init(frame: .zero); isHidden = true }
    required init?(coder: NSCoder) { fatalError() }
}
#endif
