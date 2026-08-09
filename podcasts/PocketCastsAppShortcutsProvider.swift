import AppIntents

struct PocketCastsAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetSleepTimerIntent(),
            phrases: [
                "\(.applicationName): Set sleep timer",
                "Start sleep timer in \(.applicationName)",
            ],
            shortTitle: LocalizedStringResource(
                "siri_shortcut_set_sleep_timer_title",
                defaultValue: "Set sleep timer",
                table: "AppIntents"
            ),
            systemImageName: "moon.zzz.fill"
        )
    }
}
