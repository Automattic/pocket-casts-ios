import SwiftUI
import UIKit
import PocketCastsServer

/// Renders the semantic rich text from `HTMLToAttributedStringConverter`, applying the
/// app's theming, in a remote-scrollable `UITextView` (tvOS has no `WKWebView`, and a
/// SwiftUI `ScrollView` of static `Text` won't scroll with the remote). Never goes
/// through `NSAttributedString(documentType: .html)`.
struct ScrollableTextView: View {
    let attributedText: NSAttributedString
    var scrollStep: CGFloat = 150

    /// Height of the soft fade at the top and bottom edges. The inner text view insets its
    /// text by the same amount (see `ScrollableTextRepresentable`) so the first and last
    /// lines come to rest just past the fade rather than dissolving into it.
    private let edgeFade = CGFloat(24)

    @FocusState private var isFocused: Bool
    @State private var scrollCoordinator = ScrollableTextCoordinator()

    var body: some View {
        ScrollableTextRepresentable(attributedText: attributedText, coordinator: scrollCoordinator, verticalInset: edgeFade)
            .focusable(true)
            .focused($isFocused)
            .onAppear { isFocused = true }
            .onMoveCommand { direction in
                switch direction {
                case .up:    scrollCoordinator.scroll(by: -scrollStep)
                case .down:  scrollCoordinator.scroll(by: scrollStep)
                default:     break
                }
            }
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: edgeFade)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: edgeFade)
                }
            }
    }
}

/// Drives the inner `UITextView`'s scroll offset in response to remote move-commands.
final class ScrollableTextCoordinator {
    weak var textView: UITextView?

    func scroll(by dy: CGFloat) {
        guard let textView else { return }
        let maxY = max(0, textView.contentSize.height - textView.bounds.height)
        let newY = max(0, min(maxY, textView.contentOffset.y + dy))
        textView.setContentOffset(CGPoint(x: textView.contentOffset.x, y: newY), animated: true)
    }
}

private struct ScrollableTextRepresentable: UIViewRepresentable {
    let attributedText: NSAttributedString
    let coordinator: ScrollableTextCoordinator

    /// Top/bottom padding inside the scrollable content, matched to the view's edge fade so
    /// the first and last lines rest just past the gradient instead of being clipped by it.
    let verticalInset: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.pcTextPrimary,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.attributedText = themed(attributedText)
        textView.tag = attributedText.hash
        coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.tag != attributedText.hash {
            textView.attributedText = themed(attributedText)
            textView.tag = attributedText.hash
        }
        coordinator.textView = textView
    }
}

/// Applies base font/colour, resolves `.inlinePresentationIntent` into font traits, and
/// underlines links. Paragraph rhythm comes from the converter's blank lines, so list
/// items (single newlines) stay tight.
private func themed(_ semantic: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: semantic)
    let fullRange = NSRange(location: 0, length: result.length)
    guard fullRange.length > 0 else { return result }

    let font = UIFont.preferredFont(forTextStyle: .body)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 6

    result.addAttributes([
        .font: font,
        .foregroundColor: UIColor.pcTextPrimary,
        .paragraphStyle: paragraphStyle
    ], range: fullRange)

    result.enumerateAttribute(.inlinePresentationIntent, in: fullRange) { value, range, _ in
        guard let intent = value as? InlinePresentationIntent else { return }
        var traits: UIFontDescriptor.SymbolicTraits = []
        if intent.contains(.stronglyEmphasized) { traits.insert(.traitBold) }
        if intent.contains(.emphasized) { traits.insert(.traitItalic) }
        guard !traits.isEmpty,
              let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
        result.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: range)
    }

    // Links keep the body colour; the underline is the only affordance.
    result.enumerateAttribute(.link, in: fullRange) { value, range, _ in
        guard value != nil else { return }
        result.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    }

    return result
}

#if DEBUG
#Preview("Rich text") {
    ScrollableTextView(attributedText: HTMLToAttributedStringConverter.attributedString(from: RichTextPreviewSamples.descriptionHTML))
        .frame(width: 1000, height: 760)
        .padding(80)
}
#endif
