import Foundation
import AppIntents

@available(iOS 17.2, *)
@AssistantIntent(schema: .system.search)
struct SearchPodcasts: AppIntent {

    static var title: LocalizedStringResource = "Search Podcasts"

    static var description = IntentDescription("Opens the app and serchs.")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationManager.sharedManager.navigateTo(NavigationManager.settingsProfileKey)

        return .result()
    }

    static var searchScopes: [StringSearchScope] = [.general]

    @Parameter(title: "Criteria")
    var criteria: StringSearchCriteria
}
