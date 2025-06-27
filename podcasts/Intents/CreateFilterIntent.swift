import Foundation
import AppIntents
import PocketCastsDataModel
import PocketCastsServer

struct CreateFilter: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJCreateFilterIntent"

    static var title: LocalizedStringResource = "Create Filter"
    static var description = IntentDescription("Create a new episode filter")

    static let openAppWhenRun = false

    @Parameter(title: "Filter Name")
    var filterName: String

    @Parameter(title: "Podcasts")
    var podcasts: [PodcastEntity]

    static var parameterSummary: some ParameterSummary {
        Summary("Create filter named \(\.$filterName) with \(\.$podcasts)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$filterName, \.$podcasts)) { filterName, podcasts in
            let podcastCount = podcasts.count
            return DisplayRepresentation(
                title: "Create filter \(filterName) with \(podcastCount) podcast\(podcastCount == 1 ? "" : "s")",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate filter name
        guard !filterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .result(dialog: "Filter name cannot be empty")
        }

        // Validate podcasts list
        guard !podcasts.isEmpty else {
            return .result(dialog: "At least one podcast must be selected for the filter")
        }

        // Create the filter
        let filter = EpisodeFilter()
        filter.uuid = UUID().uuidString
        filter.playlistName = filterName.trimmingCharacters(in: .whitespacesAndNewlines)
        filter.filterAllPodcasts = false
        filter.sortPosition = Int32(DataManager.sharedManager.nextSortPositionForFilter())
        filter.sortType = 0 // Default sort type
        filter.customIcon = 0 // Default icon
        filter.syncStatus = SyncStatus.notSynced.rawValue
        filter.isNew = true

        // Add podcasts to the filter
        let podcastUuids = podcasts.map { $0.id }
        filter.podcastUuids = podcastUuids.joined(separator: ",")

        // Save the filter
        DataManager.sharedManager.save(filter: filter)

        let podcastCount = podcasts.count
        let podcastNames = podcasts.prefix(3).map { $0.title }.joined(separator: ", ")
        let additionalText = podcastCount > 3 ? " and \(podcastCount - 3) more" : ""

        return .result(dialog: "Created filter '\(filter.playlistName)' with \(podcastCount) podcast\(podcastCount == 1 ? "" : "s"): \(podcastNames)\(additionalText)")
    }
}
