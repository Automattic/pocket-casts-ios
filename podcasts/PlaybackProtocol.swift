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

enum PlaybackError: LocalizedError {
    case unableToOpenFile
    case effectsPlayerFrameCountZero
    case errorDuringPlayback

    var errorDescription: String? {
        switch self {
        case .unableToOpenFile:
            return "PlaybackError: unableToOpenFile"
        case .effectsPlayerFrameCountZero:
            return "EffectsPlayer frameCount was 0 while opening the file"
        case .errorDuringPlayback:
            return "PlaybackError: errorDuringPlayback"
        }
    }
}
