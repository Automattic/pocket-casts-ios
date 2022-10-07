#if !os(watchOS)
    import UIKit

    public extension UILabel {
        func setLetterSpacing(_ letterSpacing: CGFloat) {
            guard let text = text else { return }
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: letterSpacing, range: NSRange(location: 0, length: text.count))
            attributedText = attributedString
        }

        func setTextKeepingAttributes(string: String) {
            if let newAttributedText = attributedText, let mutableAttributedText = newAttributedText.mutableCopy() as? NSMutableAttributedString {
                mutableAttributedText.mutableString.setString(string)

                attributedText = mutableAttributedText
            }
        }

        func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
            guard let labelText = text else { return }

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.lineHeightMultiple = lineHeightMultiple

            let attributedString: NSMutableAttributedString
            if let labelattributedText = attributedText {
                attributedString = NSMutableAttributedString(attributedString: labelattributedText)
            } else {
                attributedString = NSMutableAttributedString(string: labelText)
            }

            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))

            attributedText = attributedString
        }
    }
#endif
