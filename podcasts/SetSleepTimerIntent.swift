import AppIntents
import Foundation

struct SetSleepTimerIntent: AudioPlaybackIntent {
    static var title = LocalizedStringResource(
        "siri_shortcut_set_sleep_timer_title",
        defaultValue: "Set sleep timer",
        table: "AppIntents"
    )
    static var description = IntentDescription(
        LocalizedStringResource(
            "siri_shortcut_set_sleep_timer_description",
            defaultValue: "Sets the sleep timer to a chosen duration, or the duration selected in Pocket Casts when none is provided.",
            table: "AppIntents"
        )
    )
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    static var openAppWhenRun: Bool { false }

    @Parameter(
        title: LocalizedStringResource(
            "siri_shortcut_set_sleep_timer_duration_title",
            defaultValue: "Duration",
            table: "AppIntents"
        ),
        description: LocalizedStringResource(
            "siri_shortcut_set_sleep_timer_duration_description",
            defaultValue: "How long before playback stops.",
            table: "AppIntents"
        ),
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
