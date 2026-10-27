import AVFoundation
import PocketCastsDataModel

@objc protocol PlaybackProtocol: AnyObject {
    func loadEpisode(_ episode: BaseEpisode)
    var isPlaying: Bool { get }
    var isBuffering: Bool { get }
    var futureBufferAvailable: TimeInterval { get }
    func play(completion: (() -> Void)?)
    func pause()
    var playbackRate: Double { get }
    func setPlaybackRate(_ rate: Double)

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }

    func endPlayback(permanent: Bool)

    func effectsDidChange()

    var isReadyToPlay: Bool { get }

    var supportsGoogleCast: Bool { get }

    var shouldBePlaying: Bool { get }

    func routeDidChange(shouldPause: Bool)
    func interruptionDidStart()

    var internalPlayerForVideoPlayback: AVPlayer? { get }

    func setVolume(_ volume: Float)

    var currentAudioLevel: Float { get }
}
