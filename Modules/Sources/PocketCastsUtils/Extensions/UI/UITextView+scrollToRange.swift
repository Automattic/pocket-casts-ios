#if !os(watchOS)
import UIKit

extension UITextView {
    public func scrollToRange(_ range: NSRange, verticalAnchor: CGFloat = 0.5) {
        // Ensure layout is up-to-date
        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: self.textContainer)

        let finalRect = rect.offsetBy(dx: textContainerInset.left, dy: textContainerInset.top)

        var visibleRect = CGRect(
            x: finalRect.origin.x - (bounds.width / 2) + (finalRect.width / 2),
            y: finalRect.origin.y - (bounds.height * verticalAnchor) + (finalRect.height / 2),
            width: bounds.width,
            height: bounds.height
        ).inset(by: contentInset)
        visibleRect.origin.y += contentInset.bottom / 2

        if visibleRect.origin.y + visibleRect.height > contentSize.height {
            let location = text.count - 1
            let bottom = NSMakeRange(location, 1)
            scrollRangeToVisible(bottom)
            return
        }

        scrollRectToVisible(visibleRect, animated: true)
    }
}
#endif
