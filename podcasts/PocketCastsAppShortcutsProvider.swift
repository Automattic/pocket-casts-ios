import AppIntents

struct PocketCastsAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetSleepTimerIntent(),
            phrases: [
                "Set sleep timer in \(.applicationName)",
                "Start sleep timer in \(.applicationName)",
            ],
            shortTitle: "Set sleep timer",
            systemImageName: "moon.zzz.fill"
        )
    }
}
