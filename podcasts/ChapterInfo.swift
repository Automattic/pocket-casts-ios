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

    /// For generated chapters only: the original start time in the reference
    /// (generated-transcript) timeline, before it's mapped onto the played
    /// audio file's timeline via fingerprint timing. `nil` for every other
    /// chapter source, which are already expressed in the played file's timeline.
    var referenceStartTime: CMTime?
    #if !os(watchOS)
        var image: UIImage?
    #endif
    var isFirst = false
    var isLast = false
    var index = 0
    var duration: TimeInterval = 0
    var isHidden = false

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
