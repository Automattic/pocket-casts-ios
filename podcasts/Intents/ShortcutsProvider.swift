import AppIntents
import Foundation

struct ShortcutsProvider: AppShortcutsProvider {

    static var shortcutTileColor = ShortcutTileColor.red

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ChapterIntent(),
            phrases: [
                "Skip to \(\.$skipForward) chapter \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Skip chapter"),
            systemImageName: "forward.end"
        )
        AppShortcut(
            intent: SleepTimerIntent(),
            phrases: [
                "Set sleep timer for \(.applicationName)",
                "Setup sleep timer for \(.applicationName)",
                "Add sleep timer for \(.applicationName)",
            ],
            shortTitle: "Set sleep timer",
            systemImageName: ""
        )
        AppShortcut(
            intent: ExtendSleepTimerIntent(),
            phrases: ["Extend sleep timer for \(.applicationName)"],
            shortTitle: "Extend sleep timer",
            systemImageName: ""
        )
    }
}
