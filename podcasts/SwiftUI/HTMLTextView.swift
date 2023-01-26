import SwiftUI

/// Renders inline links and text using a text view since using markdown links in Text() is iOS 15+
///
struct HTMLTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor

    private let width: CGFloat
    @Binding var calculatedSize: CGSize

    init(text: String, font: UIFont, textColor: UIColor, width: CGFloat, textViewSize: Binding<CGSize>) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.width = width
        _calculatedSize = textViewSize
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.attributedText = attributedString
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.font = font
        textView.bounces = false
        textView.showsVerticalScrollIndicator = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // Run the calculation on the next runloop to prevent view issues
        DispatchQueue.main.async {
            calculatedSize = textView.sizeThatFits(CGSize(width: width, height: .infinity))
        }

        return textView
    }

    private var attributedString: NSAttributedString {
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]

        guard let data = text.data(using: .unicode),
            let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            return NSAttributedString(string: text)
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 7

        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: paragraph
        ]

        let range = NSMakeRange(0, attributedString.length)
        attributedString.addAttributes(attributes, range: range)

        return attributedString
    }

    func updateUIView(_ uiView: UITextView, context: Context) { }
}
