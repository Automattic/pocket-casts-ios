import Foundation
import AppIntents
import PocketCastsDataModel

struct FilterEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Filter"
    static var defaultQuery = FilterEntityQuery()

    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    var name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

struct FilterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FilterEntity] {
        let allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        return allFilters.compactMap { filter in
            guard identifiers.contains(filter.uuid) else { return nil }
            return FilterEntity(id: filter.uuid, name: filter.playlistName)
        }
    }

    func suggestedEntities() async throws -> [FilterEntity] {
        let allFilters = DataManager.sharedManager.allFilters(includeDeleted: false)
        return allFilters.map { filter in
            FilterEntity(id: filter.uuid, name: filter.playlistName)
        }
    }
}

struct OpenFilter: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJOpenFilterIntent"

    static var title: LocalizedStringResource = "Open Filter"
    static var description = IntentDescription("Open Filter")

    static let openAppWhenRun = true

    @Parameter(title: "Filter")
    var filter: FilterEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$filter)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$filter)) { filter in
            DisplayRepresentation(
                title: "Open \(filter?.name ?? "Filter")",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let filter {
            userActivity.title = "Open \(filter.name)"
            userActivity.suggestedInvocationPhrase = "Open \(filter.name)"
            userActivity.userInfo = ["filterUuid": filter.id]
        } else {
            userActivity.title = "Open Filter"
            userActivity.suggestedInvocationPhrase = "Open Filter"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.becomeCurrent()

        //TODO: Throw error if not found
        guard let filter else {
            return .result()
        }

        await MainActor.run {
            UIApplication.shared.open(URL(string: "pktc://shortcuts/filter/\(filter.id)")!)
        }
//        guard let filterId = filter?.id, let filter = DataManager.sharedManager.findFilter(uuid: filterId) else { return .result() }
//        NavigationManager.sharedManager.navigateTo(NavigationManager.filterPageKey, data: [NavigationManager.filterUuidKey: filter.uuid])

        return .result()
    }
}
