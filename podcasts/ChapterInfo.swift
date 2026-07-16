import AVFoundation
import Foundation
import PocketCastsUtils
#if !os(watchOS)
import UIKit
#endif

class ChapterInfo: Equatable {
    var title = ""
    var url: String?
    var startTime = CMTime(seconds: 0, preferredTimescale: 0)
    #if !os(watchOS)
        var image: UIImage?
    #endif
    var isFirst = false
    var isLast = false
    var index = 0
    var duration: TimeInterval = 0
    var isHidden = false

    /// For generated chapters, the fingerprint-resolved position on the playback
    /// timeline where this chapter actually starts. Dynamic ads shift it away
    /// from `startTime`, which is on the AI reference timeline. Set when a chapter
    /// tap resolves via `FingerprintTimingManager`; nil otherwise.
    var resolvedPlaybackStartTime: TimeInterval?

    /// The chapter's start on the playback timeline: the fingerprint-resolved
    /// position when known, otherwise the reference `startTime`. Progress display
    /// keys off this so a resolved chapter starts at 0% rather than mid-way.
    var effectiveStartTime: TimeInterval {
        resolvedPlaybackStartTime ?? startTime.seconds
    }

    /// Should only be used for sync purposes, if reading for playback
    /// use `isPlayable()` instead
    var shouldPlay = true

    func isPlayable() -> Bool {
        #if APPCLIP
        return false
        #else
        PaidFeature.deselectChapters.isUnlocked ? shouldPlay : true
        #endif
    }

    static func == (lhs: ChapterInfo, rhs: ChapterInfo) -> Bool {
        lhs.title == rhs.title && lhs.startTime.seconds == rhs.startTime.seconds && lhs.duration == rhs.duration
    }
}
