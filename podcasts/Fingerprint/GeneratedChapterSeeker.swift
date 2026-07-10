import Foundation
import PocketCastsUtils

/// Routes generated-chapter navigation through the fingerprint resolver.
///
/// Generated chapters carry reference-timeline start times that dynamic ads have
/// shifted in the listener's audio, so seeking to the raw `startTime` lands in the
/// wrong place. Both the chapters list (tap-to-seek) and the full player's
/// next/previous chapter controls go through here so they resolve the true
/// playback position first, with a graceful fallback to the raw seek. Embedded /
/// podcast-index chapters already carry real playback times and must not be
/// routed here.
enum GeneratedChapterSeeker {

    /// Whether generated-chapter navigation should resolve via fingerprinting
    /// rather than seeking to the raw reference start.
    static var isEnabled: Bool {
        FeatureFlag.generatedChapters.enabled
            && FeatureFlag.syncedTranscripts.enabled
            && PlaybackManager.shared.chaptersAreGenerated
            && PlaybackManager.shared.currentEpisode() != nil
    }

    /// Resolve `chapter` to its real playback position and seek there.
    ///
    /// - `willBeginResolving` / `didEndResolving` bracket the async fingerprint
    ///   resolve so callers can show a spinner. Neither fires on the
    ///   already-resolved cache hit, which seeks synchronously.
    /// - `startPlayback` matches each call site's existing behaviour: the chapters
    ///   list starts playback on a tap, the player's skip buttons don't.
    ///
    /// Must be called on the main queue.
    static func seek(
        to chapter: ChapterInfo,
        startPlayback: Bool,
        willBeginResolving: (() -> Void)? = nil,
        didEndResolving: (() -> Void)? = nil
    ) {
        guard let episode = PlaybackManager.shared.currentEpisode() else {
            PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: startPlayback)
            return
        }

        let episodeUuid = episode.uuid
        let referenceTime = chapter.startTime.seconds
        let fromPosition = PlaybackManager.shared.currentTime()

        // Already resolved this session — seek straight there without re-fingerprinting.
        if let seekTime = chapter.resolvedPlaybackStartTime {
            PlaybackManager.shared.seekTo(time: seekTime, startPlaybackAfterSeek: startPlayback)
            Analytics.track(.syncedTranscriptsChapterSeekUsed, properties: [
                "episode_uuid": episodeUuid,
                "from_position_seconds": Int(fromPosition),
                "to_position_seconds": Int(seekTime),
                "reference_time_seconds": Int(referenceTime)
            ])
            return
        }

        willBeginResolving?()

        FingerprintTimingManager.shared.resolvePlaybackTime(forReferenceTime: referenceTime, episode: episode) { result in
            didEndResolving?()

            // The listener switched episodes while we were resolving — the resolved
            // position is meaningless now, so don't seek.
            guard PlaybackManager.shared.currentEpisode()?.uuid == episodeUuid else {
                Analytics.track(.syncedTranscriptsChapterSeekFailed, properties: [
                    "episode_uuid": episodeUuid,
                    "reason": "episode_changed",
                    "synced_state": FingerprintTimingManager.shared.state.analyticsName,
                    "is_streaming": false
                ])
                return
            }

            switch result {
            case let .resolved(playbackTime, usedPrior, isStreaming, resolveDurationMs):
                let seekTime = ceil(playbackTime)
                // Record where the chapter actually starts on the playback timeline
                // so its progress bar fills from 0% rather than from the ad-shifted
                // offset (see `ChapterInfo.effectiveStartTime`).
                chapter.resolvedPlaybackStartTime = seekTime
                PlaybackManager.shared.seekTo(time: seekTime, startPlaybackAfterSeek: startPlayback)
                Analytics.track(.syncedTranscriptsChapterSeekUsed, properties: [
                    "episode_uuid": episodeUuid,
                    "from_position_seconds": Int(fromPosition),
                    "to_position_seconds": Int(seekTime),
                    "reference_time_seconds": Int(referenceTime),
                    "resolve_duration_ms": resolveDurationMs,
                    "used_prior": usedPrior,
                    "is_streaming": isStreaming
                ])

            case let .unresolved(reason, isStreaming):
                // Graceful fallback: seek to the raw reference-timeline start.
                PlaybackManager.shared.skipToChapter(chapter, startPlaybackAfterSkip: startPlayback)
                if reason == "region_not_local" {
                    Toast.show(L10n.transcriptTapToSeekStreamingUnavailable)
                }
                Analytics.track(.syncedTranscriptsChapterSeekFailed, properties: [
                    "episode_uuid": episodeUuid,
                    "reason": reason,
                    "synced_state": FingerprintTimingManager.shared.state.analyticsName,
                    "is_streaming": isStreaming
                ])
            }
        }
    }
}
