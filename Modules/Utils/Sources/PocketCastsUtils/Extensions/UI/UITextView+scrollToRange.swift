#if !os(watchOS)
import UIKit

extension UITextView {
    public func scrollToRange(_ range: NSRange) {
        // Ensure layout is up-to-date
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textContainer) { rect, _ in
            let finalRect = rect.offsetBy(dx: self.textContainerInset.left, dy: self.textContainerInset.top)

            // Calculate the rectangle to scroll to such that the finalRect is centered
            var visibleRect = CGRect(
                x: finalRect.origin.x - (self.bounds.width / 2) + (finalRect.width / 2),
                y: finalRect.origin.y - (self.bounds.height / 2) + (finalRect.height / 2),
                width: self.bounds.width,
                height: self.bounds.height
            ).inset(by: self.contentInset)
            visibleRect = .init(x: visibleRect.origin.x, y: visibleRect.origin.y + (self.contentInset.bottom / 2), width: visibleRect.width, height: visibleRect.height)

            if visibleRect.origin.y + visibleRect.height > self.contentSize.height {
                let location = self.text.count - 1
                let bottom = NSMakeRange(location, 1)
                self.scrollRangeToVisible(bottom)
                return
            }

            self.scrollRectToVisible(visibleRect, animated: true)
        }
    }
}
#endif
