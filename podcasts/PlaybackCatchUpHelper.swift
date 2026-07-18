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
            if episode.uuid != lastPausedEpisodeUuid() || episode.playedUpTo != lastPausedAt() { return episode.playedUpTo }

            // the pause length rewind and the interruption rewind can both apply to the same resume, take the larger of the two rather than stacking them
            let rewindAmount = max(pauseLengthRewindAmount(), interruptionRewindAmount())
            if rewindAmount <= 0 { return episode.playedUpTo }

            return max(0, episode.playedUpTo - rewindAmount)
        #endif
    }

    func playbackDidPause(of episode: BaseEpisode, dueToInterruption: Bool = false) {
        setLastPauseTimeToNow()
        setLastPausedEpisodeUuid(episode.uuid)
        setLastPausedAt(episode.playedUpTo)
        setLastPauseWasInterruption(dueToInterruption)
    }

    #if !os(watchOS)
        private func pauseLengthRewindAmount() -> TimeInterval {
            let intelligentPlaybackResumption = UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption)
            guard intelligentPlaybackResumption, let lastPauseTime = lastPauseTime() else { return 0 }

            if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 24.hours) {
                FileLog.shared.addMessage("More than 24 hours since this episode was paused, jumping back 30 seconds")
                return 30.seconds
            } else if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 1.hour) {
                FileLog.shared.addMessage("More than 1 hour since this episode was paused, jumping back 15 seconds")
                return 15.seconds
            } else if DateUtil.hasEnoughTimePassed(since: lastPauseTime, time: 5.minutes) {
                FileLog.shared.addMessage("More than 5 minutes since this episode was paused, jumping back 10 seconds")
                return 10.seconds
            }

            FileLog.shared.addMessage("Not enough time passed since this episode was last paused, no time adjustment required")
            return 0
        }

        private func interruptionRewindAmount() -> TimeInterval {
            guard FeatureFlag.interruptionRewind.enabled, lastPauseWasInterruption() else { return 0 }

            let rewindTime = UserDefaults.standard.object(forKey: Constants.UserDefaults.interruptionRewindTime) as? Int ?? Constants.Values.defaultInterruptionRewindTime
            guard rewindTime > 0 else { return 0 }

            FileLog.shared.addMessage("Playback was interrupted, jumping back \(rewindTime) seconds")
            return TimeInterval(rewindTime)
        }
    #endif

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

    // MARK: - Interruption

    private let pauseWasInterruptionKey = "lastPauseWasInterruption"
    private func lastPauseWasInterruption() -> Bool {
        UserDefaults.standard.bool(forKey: pauseWasInterruptionKey)
    }

    private func setLastPauseWasInterruption(_ wasInterruption: Bool) {
        UserDefaults.standard.setValue(wasInterruption, forKey: pauseWasInterruptionKey)
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
