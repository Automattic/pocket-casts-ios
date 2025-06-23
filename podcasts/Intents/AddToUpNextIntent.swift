import Foundation
import AppIntents
import PocketCastsDataModel
import PocketCastsServer

enum UpNextPosition: String, AppEnum {
    case top = "top"
    case bottom = "bottom"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Up Next Position"

    static let caseDisplayRepresentations: [UpNextPosition: DisplayRepresentation] = [
        .top: "Top",
        .bottom: "Bottom"
    ]
}

struct AddToUpNext: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJAddToUpNextIntent"

    static var title: LocalizedStringResource = "Add Episode to Up Next"
    static var description = IntentDescription("Add Episode to Up Next")

    static let openAppWhenRun = false

    @Parameter(title: "Episode")
    var episode: EpisodeSearchEntity

    @Parameter(title: "Position", default: .top)
    var position: UpNextPosition

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$episode) to \(\.$position) of Up Next")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$episode, \.$position)) { episode, position in
            DisplayRepresentation(
                title: "Add \(episode.title) to \(position.rawValue) of Up Next",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Parse the episode UUID from the composite ID (podcastUuid/episodeUuid)
        let components = episode.id.split(separator: "/", maxSplits: 1)
        guard components.count == 2 else {
            return .result(dialog: "Invalid episode format")
        }
        
        let episodeUuid = String(components[1])
        
        // Check if episode is already in Up Next
        if PlaybackManager.shared.queue.contains(episodeUuid: episodeUuid) {
            return .result(dialog: "\(episode.title) is already in Up Next")
        }

        // Try to find the episode in the local database first
        var episodeToAdd: BaseEpisode?

        if let localEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUuid) {
            episodeToAdd = localEpisode
        } else {
            // Create a placeholder episode for episodes not in local database
            let placeholderEpisode = Episode()
            placeholderEpisode.uuid = episodeUuid
            placeholderEpisode.title = episode.title
            placeholderEpisode.podcastUuid = episode.podcastUuid
            episodeToAdd = placeholderEpisode
        }

        guard let episodeToAdd else {
            return .result(dialog: "Could not create episode for Up Next")
        }

        // Add to Up Next using PlaybackQueue
        let toTop = (position == .top)
        PlaybackManager.shared.queue.add(episode: episodeToAdd, fireNotification: true, partOfBulkAdd: false, toTop: toTop)

        let positionText = position == .top ? L10n.top : L10n.bottom
        return .result(dialog: "Added \(episode.title) to \(positionText) of Up Next")
    }
}
