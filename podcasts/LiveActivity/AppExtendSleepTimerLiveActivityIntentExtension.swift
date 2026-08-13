import PocketCastsUtils

extension ExtendSleepTimerLiveActivityIntent {
    @MainActor
    func extendSleepTimer(by duration: TimeInterval) {
        PlaybackManager.shared.extendSleepTimer(by: duration, source: .liveActivity)
    }
}
