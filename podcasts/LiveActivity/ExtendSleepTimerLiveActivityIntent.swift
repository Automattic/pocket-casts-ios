import AppIntents
import PocketCastsUtils

struct ExtendSleepTimerLiveActivityIntent: LiveActivityIntent {
    // AppIntents extracts titles at build time, so this has to be a literal key, not `L10n`.
    static var title = LocalizedStringResource("sleep_timer_add_5_mins", defaultValue: "+ 5 Minutes")
    static var isDiscoverable = false
    static var openAppWhenRun: Bool { false }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background] }

    @MainActor
    func perform() async throws -> some IntentResult {
        extendSleepTimer(by: 5.minutes)

        return .result()
    }
}
