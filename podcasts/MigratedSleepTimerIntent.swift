import AppIntents

struct MigratedSleepTimerIntent: AudioPlaybackIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SJSleepTimerIntent"

    static var title = LocalizedStringResource(
        "siri_shortcut_set_sleep_timer_title",
        defaultValue: "Set sleep timer",
        table: "AppIntents"
    )
    static var description = IntentDescription(
        LocalizedStringResource(
            "CXbd65",
            defaultValue: "Set Sleep Timer",
            table: "Intents"
        )
    )
    static var isDiscoverable = false
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    static var openAppWhenRun: Bool { false }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background] }

    @Parameter(
        title: LocalizedStringResource(
            "siri_shortcut_migrated_sleep_timer_seconds_title",
            defaultValue: "Seconds",
            table: "AppIntents"
        )
    )
    // The property name must match the legacy intent parameter, whose values were stored in seconds.
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("siri_shortcut_set_sleep_timer_title", table: "AppIntents") {
            \.$minutes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let duration = SleepTimerIntentDuration.migratedValue(
            minutes,
            defaultDuration: Settings.customSleepTime()
        )
        _ = SiriShortcutsManager.shared.setSleepTimer(duration: duration)

        return .result()
    }
}
