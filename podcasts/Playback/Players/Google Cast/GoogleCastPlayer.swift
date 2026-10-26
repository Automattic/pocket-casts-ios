import AVFoundation
import Foundation
import PocketCastsDataModel

class GoogleCastPlayer: PlaybackProtocol {
    private lazy var castManager: GoogleCastManager = .shared

    private var shouldKeepPlaying = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - PlaybackProtocol impl

    func loadEpisode(_ episode: BaseEpisode) {
        if let episode = episode as? UserEpisode, !episode.uploaded() {
            PlaybackManager.shared.playbackDidFail(error: .chromecastError(logMessage: "Unable to cast local file"))
            return
        }
        shouldKeepPlaying = true
        castManager.playSingleEpisode(episode)
    }

    var isReadyToPlay: Bool {
        castManager.hasCastSession()
    }

    var isPlaying: Bool {
        castManager.playing()
    }

    var isBuffering: Bool {
        castManager.buffering()
    }

    var futureBufferAvailable: TimeInterval {
        duration - currentTime
    }

    func play(completion: (() -> Void)?) {
        shouldKeepPlaying = true
        castManager.play()
        completion?()

        PlaybackManager.shared.playerDidFinishPreparing()
    }

    func pause() {
        shouldKeepPlaying = false
        castManager.pause()
    }

    var playbackRate: Double {
        isPlaying ? 1.0 : 0
    }

    func setPlaybackRate(_ rate: Double) {
        // we don't support this currently
    }

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?) {
        castManager.seekToTime(time)

        completion?()
    }

    var currentTime: TimeInterval {
        if castManager.connectedOrConnectingToDevice() {
            return castManager.streamPosition()
        }

        // if we're not connected, don't trust the time the library gives back, it's often old
        return -1
    }

    var duration: TimeInterval {
        castManager.streamDuration()
    }

    func endPlayback(permanent: Bool) {
        shouldKeepPlaying = false
        if permanent {
            castManager.endPlayback()
        }
    }

    func effectsDidChange() {
        let speed = Float(PlaybackManager.shared.effects.playbackSpeed)
        castManager.changePlaybackSpeed(speed)
    }

    var supportsGoogleCast: Bool {
        true
    }

    var shouldBePlaying: Bool {
        shouldKeepPlaying
    }

    func interruptionDidStart() {
        // we're playing external, so we don't really care
    }

    func routeDidChange(shouldPause: Bool) {
        // we're playing external, so we don't really care
    }

    var internalPlayerForVideoPlayback: AVPlayer? {
        nil
    }

    // MARK: - Volume

    func setVolume(_ volume: Float) {
        // not supported
    }

    var currentAudioLevel: Float {
        // not supported
        return 0
    }
}
