import PocketCastsUtils

@available(iOS 17.0, *)
extension ExtendSleepTimerLiveActivityIntent {
    @MainActor
    func extendSleepTimer(by duration: TimeInterval) {
        PlaybackManager.shared.extendSleepTimer(by: duration, source: .liveActivity)
    }
}
