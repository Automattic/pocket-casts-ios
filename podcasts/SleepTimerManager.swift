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
                Analytics.shared.track(.playerSleepTimerRestarted, properties: ["duration": duration])
                FileLog.shared.addMessage("Sleep Timer: restarting it automatically")
            } else if setting.sleepOnEpisodeEnd == true {
                observePlaybackEndAndReactivateTime()
            }
        }
    }

    private func observePlaybackEndAndReactivateTime() {
        NotificationCenter.default.addObserver(self, selector: #selector(playbackTrackChanged), name: Constants.Notifications.playbackTrackChanged, object: nil)
    }

    @objc private func playbackTrackChanged() {
        FileLog.shared.addMessage("Sleep Timer: restarting it automatically to the end of the episode")
        Analytics.shared.track(.playerSleepTimerRestarted, properties: ["duration": "end_of_episode"])
        PlaybackManager.shared.sleepOnEpisodeEnd = true
        NotificationCenter.default.removeObserver(self)
    }

    struct SleepTimerSetting: JSONEncodable, JSONDecodable {
        let duration: TimeInterval?
        let sleepOnEpisodeEnd: Bool?
    }
}
