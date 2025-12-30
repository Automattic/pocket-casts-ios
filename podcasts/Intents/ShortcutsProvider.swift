import Foundation
import AppIntents

struct ShortcutsProvider: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ChapterIntent(defaultSkip: .previous),
            phrases: [AppShortcutPhrase(L10n.siriShortcutPreviousChapter)],
            shortTitle: LocalizedStringResource("siri_shortcut_previous_chapter"),
            systemImageName: "siri_chapter_previous"
        )
        AppShortcut(
            intent: ChapterIntent(defaultSkip: .next),
            phrases: [AppShortcutPhrase(L10n.siriShortcutNextChapter)],
            shortTitle: LocalizedStringResource("siri_shortcut_next_chapter"),
            systemImageName: "siri_chapter_next"
        )
        AppShortcut(
            intent: SleepTimerIntent(),
            phrases: ["Set sleep timer for \(.applicationName)"],
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
