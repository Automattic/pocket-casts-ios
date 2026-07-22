import AppIntents

struct MigratedSleepTimerIntent: AudioPlaybackIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "SJSleepTimerIntent"

    static var title: LocalizedStringResource = "Set sleep timer"
    static var description = IntentDescription("Sets the Pocket Casts sleep timer.")
    static var isDiscoverable = false
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    static var openAppWhenRun: Bool { false }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background] }

    @Parameter(title: "Minutes")
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Set sleep timer for \(\.$minutes) minutes")
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
