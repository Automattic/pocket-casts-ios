import AVFoundation
import Foundation

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

    /// Should only be used for sync purposes, if reading for playback
    /// use `isPlayable()` instead
    var shouldPlay = true

    func isPlayable() -> Bool {
        FeatureFlag.deselectChapters.enabled && PaidFeature.deselectChapters.isUnlocked ? shouldPlay : true
    }

    static func == (lhs: ChapterInfo, rhs: ChapterInfo) -> Bool {
        lhs.title == rhs.title && lhs.startTime.seconds == rhs.startTime.seconds && lhs.duration == rhs.duration
    }
}
