#if !os(watchOS)
import UIKit

extension UITextView {
    public func scrollToRange(_ range: NSRange) {
        // Ensure layout is up-to-date
        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textContainer) { [weak self] rect, _ in
            guard let self else { return }

            let finalRect = rect.offsetBy(dx: textContainerInset.left, dy: textContainerInset.top)

            // Calculate the rectangle to scroll to such that the finalRect is centered
            var visibleRect = CGRect(
                x: finalRect.origin.x - (bounds.width / 2) + (finalRect.width / 2),
                y: finalRect.origin.y - (bounds.height / 2) + (finalRect.height / 2),
                width: bounds.width,
                height: bounds.height
            ).inset(by: contentInset)
            visibleRect = .init(x: visibleRect.origin.x, y: visibleRect.origin.y + (contentInset.bottom / 2), width: visibleRect.width, height: visibleRect.height)

            if visibleRect.origin.y + visibleRect.height > contentSize.height {
                let location = text.count - 1
                let bottom = NSMakeRange(location, 1)
                scrollRangeToVisible(bottom)
                return
            }

            scrollRectToVisible(visibleRect, animated: true)
        }
    }
}
#endif
