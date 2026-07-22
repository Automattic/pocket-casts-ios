import AppIntents

struct SetSleepTimerIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Set sleep timer"
    static var description = IntentDescription("Sets the sleep timer to the duration selected in Pocket Casts.")
    static var authenticationPolicy: IntentAuthenticationPolicy { .alwaysAllowed }
    static var openAppWhenRun: Bool { false }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background] }

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = SiriShortcutsManager.shared.setSleepTimer(duration: Settings.customSleepTime())

        return .result()
    }
}
