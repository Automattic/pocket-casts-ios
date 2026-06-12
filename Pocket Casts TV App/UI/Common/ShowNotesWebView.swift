import SwiftUI
import UIKit

/// Renders raw HTML show notes in a scroll-and-focus pattern that works on
/// tvOS.
///
/// tvOS lacks `WKWebView`, so HTML is parsed into an `NSAttributedString` and
/// rendered by a `UITextView` (the only readily-available rich-text renderer)
/// with its own scroll view. SwiftUI then owns focus and remote-input handling:
/// `.focusable(true)` + `@FocusState` claims focus when the sheet opens, and
/// `.onMoveCommand` translates remote swipes / simulator arrow keys into
/// programmatic scrolls on the `UITextView` via a small coordinator.
struct ShowNotesWebView: View {
    let html: String

    @FocusState private var isFocused: Bool
    @State private var scrollCoordinator = ShowNotesScrollCoordinator()

    var body: some View {
        ShowNotesAttributedTextView(html: html, coordinator: scrollCoordinator)
            .focusable(true)
            .focused($isFocused)
            .onAppear { isFocused = true }
            .onMoveCommand { direction in
                switch direction {
                case .up:    scrollCoordinator.scroll(by: -150)
                case .down:  scrollCoordinator.scroll(by: 150)
                default:     break
                }
            }
    }
}

/// Holds a weak reference to the inner `UITextView` so SwiftUI move-commands
/// can drive its scroll offset.
final class ShowNotesScrollCoordinator {
    weak var textView: UITextView?

    func scroll(by dy: CGFloat) {
        guard let textView else { return }
        let maxY = max(0, textView.contentSize.height - textView.bounds.height)
        let newY = max(0, min(maxY, textView.contentOffset.y + dy))
        textView.setContentOffset(CGPoint(x: textView.contentOffset.x, y: newY), animated: true)
    }
}

private struct ShowNotesAttributedTextView: UIViewRepresentable {
    let html: String
    let coordinator: ShowNotesScrollCoordinator

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.attributedText = makeAttributedString()
        coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = makeAttributedString()
        coordinator.textView = textView
    }

    private func makeAttributedString() -> NSAttributedString {
        let wrapped = """
        <html><head><style>
        body { color: #FBFBFC; font-family: -apple-system; font-size: 28px; line-height: 1.4; }
        a { color: #F43769; text-decoration: underline; }
        h1, h2, h3, h4, h5, h6 { color: #FBFBFC; font-weight: 600; }
        img { display: none; }
        </style></head><body>\(html)</body></html>
        """
        guard let data = wrapped.data(using: .utf8) else {
            return NSAttributedString(string: html)
        }
        let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributed ?? NSAttributedString(string: html)
    }
}
