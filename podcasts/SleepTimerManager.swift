import Foundation
import PocketCastsUtils

class SleepTimerManager {
    private var restartSleepTimerIfPlayingAgainWithin: TimeInterval = 5.minutes

    func recordSleepTimerFinished() {
        Settings.sleepTimerFinishedDate = .now
    }

    func recordSleepTimerDuration(duration: TimeInterval?, onEpisodeEnd: Bool?) {
        let setting = SleepTimerSetting(duration: duration, sleepOnEpisodeEnd: onEpisodeEnd)
        Settings.sleepTimerLastSetting = setting
    }

    func restartSleepTimerIfNeeded() {
        if let sleepTimerFinishedDate = Settings.sleepTimerFinishedDate,
           Date.now.timeIntervalSince(sleepTimerFinishedDate) <= restartSleepTimerIfPlayingAgainWithin,
           let setting = Settings.sleepTimerLastSetting {
            if let duration = setting.duration {
                PlaybackManager.shared.setSleepTimerInterval(duration)
            } else if setting.sleepOnEpisodeEnd == true {
                observePlaybackEndAndReactivateTime()
            }
        }
    }

    private func observePlaybackEndAndReactivateTime() {
        NotificationCenter.default.addObserver(self, selector: #selector(playbackTrackChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
    }

    @objc private func playbackTrackChanged() {
        PlaybackManager.shared.sleepOnEpisodeEnd = true
        NotificationCenter.default.removeObserver(self)
    }

    struct SleepTimerSetting: JSONEncodable, JSONDecodable {
        let duration: TimeInterval?
        let sleepOnEpisodeEnd: Bool?
    }
}
