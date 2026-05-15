import AppIntents
import PocketCastsUtils

@available(iOS 17.0, *)
struct ExtendSleepTimerLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add 5 Minutes"
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
