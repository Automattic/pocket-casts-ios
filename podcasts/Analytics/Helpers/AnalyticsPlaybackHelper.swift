import PocketCastsUtils
import PocketCastsDataModel
import Foundation

/// Helper used to track playback
class AnalyticsPlaybackHelper: AnalyticsCoordinator {
    static var shared = AnalyticsPlaybackHelper()

    /// Whether to ignore the next seek event
    private var ignoreNextSeek = false

    /// Timestamp of the last tvOS remote play/pause action, used to de-duplicate analytics events between
    /// remote handlers and TV player observation.
    var timestampOfLastRemoteAction: Date?

    func play() {
        track(.playbackPlay, properties: Self.hlsLifecycleProperties(for: PlaybackManager.shared.currentEpisode))
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

    func chapterSkipped(properties: [String: Any]?) {
        track(.playbackChapterSkipped, properties: properties)
    }

    func viewDidAppear(currentSettings: String) {
        track(.playbackEffectSettingsViewAppeared, properties: ["settings": currentSettings])
    }

    func effectSettingsChanged(currentSettings: String) {
        track(.playbackEffectSettingsChanged, properties: ["settings": currentSettings])
    }

    func playbackFailed(episode: BaseEpisode?, error: String, hlsErrorDetail: String?, player: PlaybackProtocol?) {
        var properties: [String: Any] = ["episode_uuid": episode?.uuid ?? "unknown",
                                         "podcast_uuid": episode?.parentIdentifier() ?? "unknown",
                                         "error": error,
                                         "player": playerString(player: player)]

        // HLS context so HLS failures can be told apart from progressive (MP3) ones. Gated behind
        // the HLS flag so it only ships while HLS playback is enabled — mirrors the web player.
        if FeatureFlag.hls.enabled, let episode {
            properties.merge(Self.hlsProtocolProperties(for: episode)) { current, _ in current }
            if EpisodeManager.hasHLSStream(episode), let hlsErrorDetail {
                properties["hls_error_detail"] = hlsErrorDetail
            }
        }

        track(.playbackFailed, properties: properties)
    }

    /// Emitted once playback actually starts, reporting the protocol the source resolved to.
    /// Empty/no-op unless the HLS feature flag is on. Mirrors the web player's
    /// `playback_source_resolved` event.
    func playbackSourceResolved(for episode: BaseEpisode?) {
        guard FeatureFlag.hls.enabled, let episode else { return }

        var properties: [String: Any] = ["episode_uuid": episode.uuid,
                                         "podcast_uuid": episode.parentIdentifier(),
                                         // iOS selects one protocol up front (no runtime HLS->progressive
                                         // retry), so this is always false; kept for parity with Android.
                                         "is_fallback": false]
        properties.merge(Self.hlsProtocolProperties(for: episode)) { current, _ in current }

        track(.playbackSourceResolved, properties: properties)
    }

    /// Emitted when the user switches an HLS video stream between video and audio-only rendering.
    /// Mirrors the web player's `playback_hls_toggled`.
    func videoRenderingToggled(switchedToVideo: Bool, episode: BaseEpisode?) {
        guard FeatureFlag.hls.enabled, let episode else { return }

        track(.playbackHlsToggled, properties: ["switched_to": switchedToVideo ? "video" : "audio",
                                                "episode_uuid": episode.uuid,
                                                "podcast_uuid": episode.parentIdentifier()])
    }

    enum PlayerSource: String {
        case fullPlayer = "full_player"
        case miniPlayer = "mini_player"
    }

    func playbackErrorShown(playerSource: PlayerSource) {
        track(.playbackErrorShown, properties: ["player_source": playerSource.rawValue])
    }

    func playbackErrorTapped(playerSource: PlayerSource) {
        track(.playbackErrorTapped, properties: ["player_source": playerSource.rawValue])
    }

    private func track(_ event: AnalyticsEvent, currentSettings: String?, properties: [String: Any]? = nil) {
        var properties = properties
        if let currentSettings {
            properties?["settings"] = currentSettings
        }
        track(event, properties: properties)
    }

    // MARK: - HLS

    /// HLS-related properties for playback lifecycle events (play / completed / autoplayed).
    /// Returns an empty dictionary unless the HLS feature flag is on, so these properties only ship
    /// while HLS playback is enabled — mirrors the web player's `getHlsPlaybackProperties`.
    /// `hls_available` reflects whether the episode *offers* an HLS stream; the protocol actually
    /// played is reported separately via `playback_source_resolved`.
    ///
    /// Pass `isCurrentEpisode: false` for an episode that hasn't started yet (e.g. the next autoplay
    /// episode): the per-session video toggle only applies to the episode currently playing, so
    /// `audio_only_mode` should reflect just the global "Audio only" setting for an upcoming one.
    static func hlsLifecycleProperties(for episode: BaseEpisode?, isCurrentEpisode: Bool = true) -> [String: Any] {
        guard FeatureFlag.hls.enabled else { return [:] }
        var properties: [String: Any] = ["hls_available": episodeOffersHLS(episode)]
        if let audioOnlyMode = audioOnlyMode(for: episode, isCurrentEpisode: isCurrentEpisode) {
            properties["audio_only_mode"] = audioOnlyMode
        }
        return properties
    }

    /// The audio-only listening state, but only for episodes actually streaming via HLS (mirrors
    /// Android's `audioOnlyModeOrNull`). `nil` — and therefore omitted — for progressive or downloaded
    /// playback, where there's no video surface to suppress.
    ///
    /// For the episode currently playing this is the full state (global setting OR per-session toggle).
    /// For an episode that hasn't started yet the per-session toggle doesn't apply — it resets to video
    /// when the episode opens — so only the global "Audio only" setting carries over.
    private static func audioOnlyMode(for episode: BaseEpisode?, isCurrentEpisode: Bool) -> Bool? {
        guard let episode, EpisodeManager.willPlayViaHLS(episode) else { return nil }
        let manager = PlaybackManager.shared
        return isCurrentEpisode ? manager.isAudioOnlyMode : manager.isAudioOnlyForced
    }

    /// The protocol an episode's source resolves to for playback (`hls`/`progressive`), for events
    /// where the source is known. Empty unless the HLS feature flag is on.
    static func hlsProtocolProperties(for episode: BaseEpisode) -> [String: Any] {
        guard FeatureFlag.hls.enabled else { return [:] }
        return ["playback_protocol": EpisodeManager.willPlayViaHLS(episode) ? "hls" : "progressive"]
    }

    /// Whether the episode advertises an HLS stream, independent of whether it's the selected source.
    private static func episodeOffersHLS(_ episode: BaseEpisode?) -> Bool {
        guard let episode = episode as? Episode, let hlsUrl = episode.hlsUrl else { return false }
        return !hlsUrl.isEmpty
    }

    func playerString(player: PlaybackProtocol?) -> String {
        #if !os(watchOS) && !APPCLIP && !os(tvOS)
        if player is GoogleCastPlayer {
            return "google_cast"
        }
        #endif

        #if !os(watchOS) && !os(tvOS)
        if player is EffectsPlayer {
            return "effects"
        }
        #endif

        if player is DefaultPlayer {
            return "default"
        } else {
            return "unknown"
        }
    }
}
