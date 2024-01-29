import PocketCastsUtils

/// Helper used to track playback
class AnalyticsPlaybackHelper: AnalyticsCoordinator {
    static var shared = AnalyticsPlaybackHelper()

    /// Whether to ignore the next seek event
    private var ignoreNextSeek = false

    private var isVideoPodcast: Bool {
        PlaybackManager.shared.currentEpisode()?.videoPodcast() ?? false
    }

    func play() {
        track(.playbackPlay, properties: ["content_type": isVideoPodcast ? "video" : "audio"])
    }

    func pause() {
        track(.playbackPause, properties: ["content_type": isVideoPodcast ? "video" : "audio"])
    }

    func skipBack() {
        ignoreNextSeek = true
        track(.playbackSkipBack)
    }

    func skipForward() {
        ignoreNextSeek = true
        track(.playbackSkipForward)
    }

    func seek(from: TimeInterval, to: TimeInterval, duration: TimeInterval) {
        // Currently ignore a seek event that is triggered by a sync process
        // Using the skip buttons triggers a seek, ignore this as well
        guard currentSource != .sync, ignoreNextSeek == false else {
            ignoreNextSeek = false
            return
        }

        let from = (from / duration)
        let to = (to / duration)

        // Validate the values are valid
        guard from.isNumeric, to.isNumeric else { return }

        // Use percents to relativize the seeking across any duration episode
        let seekFrom = Int(from * 100)
        let seekPercent = Int(to * 100)

        track(.playbackSeek, properties: ["seek_to_percent": seekPercent, "seek_from_percent": seekFrom])
    }

    func playbackSpeedChanged(to speed: Double) {
        track(.playbackEffectSpeedChanged, properties: ["speed": speed])
    }

    func trimSilenceToggled(enabled: Bool) {
        track(.playbackEffectTrimSilenceToggled, properties: ["enabled": enabled])
    }

    func trimSilenceAmountChanged(amount: TrimSilenceAmount) {
        track(.playbackEffectTrimSilenceAmountChanged, properties: ["amount": amount.analyticsDescription])
    }

    func volumeBoostToggled(enabled: Bool) {
        track(.playbackEffectVolumeBoostToggled, properties: ["enabled": enabled])
    }
}
