import UIKit

/// Helper used to track playback
class AnalyticsPlaybackHelper: AnalyticsCoordinator {
    static var shared = AnalyticsPlaybackHelper()

    /// Whether to ignore the next seek event
    private var ignoreNextSeek = false

    func play() {
        track(.playbackPlay)
    }

    func pause() {
        track(.playbackPause)
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
        guard currentSource != "sync", ignoreNextSeek == false else {
            ignoreNextSeek = false
            return
        }

        // Use percents to relativize the seeking across any duration episode
        let seekFrom = Int((from / duration) * 100)
        let seekPercent = Int((to / duration) * 100)

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
