import PocketCastsUtils
import PocketCastsDataModel

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

    func playbackSpeedChanged(to speed: Double, currentSettings: String? = nil) {
        track(.playbackEffectSpeedChanged, currentSettings: currentSettings, properties: ["speed": speed])
    }

    func trimSilenceToggled(enabled: Bool, currentSettings: String? = nil) {
        track(.playbackEffectTrimSilenceToggled, currentSettings: currentSettings, properties: ["enabled": enabled])
    }

    func trimSilenceAmountChanged(amount: TrimSilenceAmount, currentSettings: String? = nil) {
        track(.playbackEffectTrimSilenceAmountChanged, currentSettings: currentSettings, properties: ["amount": amount.analyticsDescription])
    }

    func volumeBoostToggled(enabled: Bool, currentSettings: String? = nil) {
        track(.playbackEffectVolumeBoostToggled, currentSettings: currentSettings, properties: ["enabled": enabled])
    }

    func chapterSkipped() {
        track(.playbackChapterSkipped)
    }

    func viewDidAppear(currentSettings: String) {
        track(.playbackEffectSettingsViewAppeared, properties: ["settings": currentSettings])
    }

    func effectSettingsChanged(currentSettings: String) {
        track(.playbackEffectSettingsChanged, properties: ["settings": currentSettings])
    }

    private func track(_ event: AnalyticsEvent, currentSettings: String?, properties: [String: Any]? = nil) {
        var properties = properties
        if let currentSettings {
            properties?["settings"] = currentSettings
        }
        track(event, properties: properties)
    }
}
