import AppIntents

@available(iOS 17.2, *)
struct PodcastsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchPodcasts(),
              phrases: [
                "Find \(\.$criteria) in \(.applicationName)",
                "Search for \(\.$criteria) in \(.applicationName)",
              ],
              shortTitle: "Search <app name redacted>",
              systemImageName: "magnifyingglass"
        )
    }
}
