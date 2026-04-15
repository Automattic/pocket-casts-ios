#if !os(watchOS)
    import UIKit

    public extension UIButton {
        func setLetterSpacing(_ letterSpacing: CGFloat) {
            guard let title = titleLabel?.text else { return }
            let attributedString = NSMutableAttributedString(string: title)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: letterSpacing, range: NSRange(location: 0, length: title.count))
            setAttributedTitle(attributedString, for: .normal)
        }
    }
#endif
