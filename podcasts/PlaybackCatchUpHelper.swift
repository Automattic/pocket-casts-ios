import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import PocketCastsServer

struct PlaybackCatchUpHelper {
    func adjustStartTimeIfNeeded(for episode: BaseEpisode) -> TimeInterval {
        // since this setting doesn't exit on Apple Watch, return the actual time
        #if os(watchOS)
            return episode.playedUpTo
        #else
            // if it's a different episode, or not still at the time it was at when it was last paused, just play from where it's up to
            let intelligentPlaybackResumption: Bool
            if FeatureFlag.settingsSync.enabled {
                intelligentPlaybackResumption = SettingsStore.appSettings.intelligentResumption
            } else {
                intelligentPlaybackResumption = UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption)
            }
            if !intelligentPlaybackResumption || episode.uuid != lastPausedEpisodeUuid() || episode.playedUpTo != lastPausedAt() { return episode.playedUpTo }

            guard let lastPauseTime = lastPauseTime() else { return episode.playedUpTo }

            if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 24.hours) {
                FileLog.shared.addMessage("More than 24 hours since this episode was paused, jumping back 30 seconds")
                return max(0, episode.playedUpTo - 30.seconds)
            } else if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 1.hour) {
                FileLog.shared.addMessage("More than 1 hour since this episode was paused, jumping back 15 seconds")
                return max(0, episode.playedUpTo - 15.seconds)
            } else if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 5.minutes) {
                FileLog.shared.addMessage("More than 5 minutes since this episode was paused, jumping back 10 seconds")
                return max(0, episode.playedUpTo - 10.seconds)
            }

            FileLog.shared.addMessage("Not enough time passed since this episode was last paused, no time adjustment required")
            return episode.playedUpTo
        #endif
    }

    func playbackDidPause(of episode: BaseEpisode) {
        setLastPauseTimeToNow()
        setLastPausedEpisodeUuid(episode.uuid)
        setLastPausedAt(episode.playedUpTo)
    }

    // MARK: - Pause Time

    private let pauseTimeKey = "lastPauseTime"
    private func lastPauseTime() -> Date? {
        guard let time = UserDefaults.standard.object(forKey: pauseTimeKey) as? Date else { return nil }

        return time
    }

    private func setLastPauseTimeToNow() {
        UserDefaults.standard.setValue(Date(), forKey: pauseTimeKey)
    }

    // MARK: - Paused Episode

    private let pausedEpisodeUuidKey = "lastPausedEpisode"
    private func lastPausedEpisodeUuid() -> String? {
        guard let uuid = UserDefaults.standard.object(forKey: pausedEpisodeUuidKey) as? String else { return nil }

        return uuid
    }

    private func setLastPausedEpisodeUuid(_ uuid: String) {
        UserDefaults.standard.setValue(uuid, forKey: pausedEpisodeUuidKey)
    }

    // MARK: - Paused At

    private let pausedAtKey = "lastPausedAt"
    private func lastPausedAt() -> Double? {
        guard let time = UserDefaults.standard.object(forKey: pausedAtKey) as? Double else { return nil }

        return time
    }

    private func setLastPausedAt(_ time: Double) {
        UserDefaults.standard.setValue(time, forKey: pausedAtKey)
    }
}
