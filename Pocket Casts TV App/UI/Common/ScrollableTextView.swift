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

    @FocusState private var isFocused: Bool
    @State private var scrollCoordinator = ScrollableTextCoordinator()

    var body: some View {
        ScrollableTextRepresentable(attributedText: attributedText, coordinator: scrollCoordinator)
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

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
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

/// Applies base font/colour, resolves `emphasisAttributeKey` into font traits, and
/// colours links. Paragraph rhythm comes from the converter's blank lines, so list
/// items (single newlines) stay tight.
private func themed(
    _ semantic: NSAttributedString,
    font: UIFont = .preferredFont(forTextStyle: .body),
    textColor: UIColor = .pcTextPrimary,
    linkColor: UIColor = .pcLink,
    lineSpacing: CGFloat = 6
) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: semantic)
    let fullRange = NSRange(location: 0, length: result.length)
    guard fullRange.length > 0 else { return result }

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = lineSpacing

    result.addAttributes([
        .font: font,
        .foregroundColor: textColor,
        .paragraphStyle: paragraphStyle
    ], range: fullRange)

    result.enumerateAttribute(HTMLToAttributedStringConverter.emphasisAttributeKey, in: fullRange) { value, range, _ in
        guard let raw = (value as? NSNumber)?.intValue else { return }
        let emphasis = HTMLToAttributedStringConverter.Emphasis(rawValue: raw)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if emphasis.contains(.bold) { traits.insert(.traitBold) }
        if emphasis.contains(.italic) { traits.insert(.traitItalic) }
        guard !traits.isEmpty,
              let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
        result.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: range)
    }

    result.enumerateAttribute(.link, in: fullRange) { value, range, _ in
        guard value != nil else { return }
        result.addAttributes([
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ], range: range)
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
