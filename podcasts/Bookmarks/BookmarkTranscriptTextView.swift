import UIKit

/// A transcript text view that reports the first layout pass it can scroll and select in,
/// and can mark the line the bookmark sits on with a glyph in the leading gutter.
class BookmarkTranscriptTextView: UITextView {
    /// The gutter the text keeps on both sides, which the indicator sits inside of
    static let gutterWidth: CGFloat = 28

    var onFirstLayout: (() -> Void)?

    private var bookmarkedCharacterIndex: Int?
    private var bookmarkIndicator: UIImageView?

    /// Marks the line holding `characterIndex` with a bookmark glyph in the leading gutter
    func showBookmarkIndicator(at characterIndex: Int, color: UIColor) {
        let configuration = UIImage.SymbolConfiguration(pointSize: BookmarkTranscriptStyle.fontSize, weight: .semibold)
        let indicator = UIImageView(image: UIImage(systemName: "bookmark.fill", withConfiguration: configuration))
        indicator.tintColor = color
        indicator.sizeToFit()
        addSubview(indicator)

        bookmarkIndicator = indicator
        bookmarkedCharacterIndex = characterIndex
    }

    /// Recolors the indicator where it stands, for theme changes
    func setBookmarkIndicatorColor(_ color: UIColor) {
        bookmarkIndicator?.tintColor = color
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutBookmarkIndicator()

        guard window != nil, bounds.width > 0, let onFirstLayout else { return }

        // Cleared first: the callback lays the text out again as it scrolls
        self.onFirstLayout = nil
        onFirstLayout()
    }

    /// Pins the indicator to the line fragment its character is laid out on, so it stays
    /// with its line whatever width the text wraps to
    private func layoutBookmarkIndicator() {
        guard let bookmarkIndicator, let bookmarkedCharacterIndex, textStorage.length > 0 else { return }

        let characterIndex = min(max(bookmarkedCharacterIndex, 0), textStorage.length - 1)
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)

        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let gutterCenter = Self.gutterWidth / 2
        bookmarkIndicator.center = CGPoint(x: isRightToLeft ? bounds.width - gutterCenter : gutterCenter,
                                           y: lineRect.midY + textContainerInset.top)
    }
}

// MARK: - Reference time lookup

extension TranscriptModel {
    /// The character the given reference-timeline position lands on, interpolated within
    /// its cue so a long cue that wraps over several lines still points at the right one
    func characterIndex(at time: TimeInterval) -> Int? {
        guard let cue = nearestCue(to: time) else { return nil }

        let duration = cue.endTime - cue.startTime
        let fraction = duration > 0 ? min(max((time - cue.startTime) / duration, 0), 1) : 0
        let range = cue.characterRange
        guard range.length > 0 else { return range.location }

        return range.location + min(Int(fraction * Double(range.length)), range.length - 1)
    }

    /// The cue the time falls in, or the closest one when it lands in the silence between cues
    private func nearestCue(to time: TimeInterval) -> TranscriptCue? {
        firstCue(containing: time) ?? cues.min { $0.distance(to: time) < $1.distance(to: time) }
    }
}

private extension TranscriptCue {
    /// How far outside the cue's time span the given time falls; 0 within it
    func distance(to time: TimeInterval) -> TimeInterval {
        max(startTime - time, time - endTime, 0)
    }
}
