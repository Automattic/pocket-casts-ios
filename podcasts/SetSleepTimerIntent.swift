import AppIntents
import Foundation

struct SetSleepTimerIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Set sleep timer"
    static var description = IntentDescription("Sets the sleep timer to a chosen duration, or the duration selected in Pocket Casts when none is provided.")
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    static var openAppWhenRun: Bool { false }

    @Parameter(
        title: "Duration",
        description: "How long before playback stops.",
        defaultUnit: .minutes,
        supportsNegativeNumbers: false
    )
    var duration: Measurement<UnitDuration>?

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background] }

    @MainActor
    func perform() async throws -> some IntentResult {
        let duration = SleepTimerIntentDuration.resolvedValue(
            duration,
            defaultDuration: Settings.customSleepTime()
        )
        _ = SiriShortcutsManager.shared.setSleepTimer(duration: duration)

        return .result()
    }
}
