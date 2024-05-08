import AVFoundation
import PocketCastsDataModel

@objc protocol PlaybackProtocol: AnyObject {
    func loadEpisode(_ episode: BaseEpisode)
    func playing() -> Bool
    func buffering() -> Bool
    func futureBufferAvailable() -> TimeInterval
    func play(completion: (() -> Void)?)
    func pause()
    func playbackRate() -> Double
    func setPlaybackRate(_ rate: Double)

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?)
    func currentTime() -> TimeInterval
    func duration() -> TimeInterval

    func endPlayback(permanent: Bool)

    func effectsDidChange()

    func supportsSilenceRemoval() -> Bool
    func supportsVolumeBoost() -> Bool
    func supportsGoogleCast() -> Bool
    func supportsStreaming() -> Bool
    func supportsAirplay2() -> Bool

    func shouldBePlaying() -> Bool

    func routeDidChange(shouldPause: Bool)
    func interruptionDidStart()

    func internalPlayerForVideoPlayback() -> AVPlayer?
}

enum PlaybackError: Error {
    case unableToOpenFile
    case errorDuringPlayback
}
