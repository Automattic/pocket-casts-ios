import SwiftUI
import UIKit

struct NonEditableTextView: UIViewRepresentable {
    let text: String
    let scrolledToBottom: Bool

    init(text: String, scrolledToBottom: Bool = false) {
        self.text = text
        self.scrolledToBottom = scrolledToBottom
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.font = UIFont.preferredFont(forTextStyle: .body)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text

        if scrolledToBottom {
            let bottomOffset = CGPoint(
                x: 0,
                y: max(0, uiView.contentSize.height - uiView.bounds.height + uiView.contentInset.bottom)
            )
            uiView.setContentOffset(bottomOffset, animated: false)
        }
    }
}
