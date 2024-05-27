import AVFoundation
import Foundation
import PocketCastsDataModel

class GoogleCastPlayer: PlaybackProtocol {
    private lazy var castManager: GoogleCastManager = .sharedManager

    private var shouldKeepPlaying = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - PlaybackProtocol impl

    func loadEpisode(_ episode: BaseEpisode) {
        if let episode = episode as? UserEpisode, !episode.uploaded() {
            PlaybackManager.shared.playbackDidFail(logMessage: "Unable to cast local file",
                                                   userMessage: L10n.chromecastError)
            return
        }
        shouldKeepPlaying = true
        castManager.playSingleEpisode(episode)
    }

    func playing() -> Bool {
        castManager.playing()
    }

    func buffering() -> Bool {
        castManager.buffering()
    }

    func futureBufferAvailable() -> TimeInterval {
        duration() - currentTime()
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

    func playbackRate() -> Double {
        playing() ? 1.0 : 0
    }

    func setPlaybackRate(_ rate: Double) {
        // we don't support this currently
    }

    func seekTo(_ time: TimeInterval, completion: (() -> Void)?) {
        castManager.seekToTime(time)

        completion?()
    }

    func currentTime() -> TimeInterval {
        if castManager.connectedOrConnectingToDevice() {
            return castManager.streamPosition()
        }

        // if we're not connected, don't trust the time the library gives back, it's often old
        return -1
    }

    func duration() -> TimeInterval {
        castManager.streamDuration()
    }

    func endPlayback(permanent: Bool) {
        shouldKeepPlaying = false
        if permanent {
            castManager.endPlayback()
        }
    }

    func effectsDidChange() {
        let speed = Float(PlaybackManager.shared.effects().playbackSpeed)
        castManager.changePlaybackSpeed(speed)
    }

    func supportsSilenceRemoval() -> Bool {
        false
    }

    func supportsVolumeBoost() -> Bool {
        false
    }

    func supportsGoogleCast() -> Bool {
        true
    }

    func supportsStreaming() -> Bool {
        true
    }

    func supportsAirplay2() -> Bool {
        false
    }

    func shouldBePlaying() -> Bool {
        shouldKeepPlaying
    }

    func interruptionDidStart() {
        // we're playing external, so we don't really care
    }

    func routeDidChange(shouldPause: Bool) {
        // we're playing external, so we don't really care
    }

    func internalPlayerForVideoPlayback() -> AVPlayer? {
        nil
    }

    // MARK: - Volume

    func setVolume(_ volume: Float) {
        // not supported
    }
}
