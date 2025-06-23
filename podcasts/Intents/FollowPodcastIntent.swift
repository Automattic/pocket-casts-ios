import Foundation
import AppIntents
import PocketCastsDataModel
import PocketCastsServer

struct FollowPodcast: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJFollowPodcastIntent"

    static var title: LocalizedStringResource = "Follow Podcast"
    static var description = IntentDescription("Follow Podcast")

    static let openAppWhenRun = false

    @Parameter(title: "Podcast")
    var podcast: PodcastEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Follow \(\.$podcast)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$podcast)) { podcast in
            DisplayRepresentation(
                title: "Follow \(podcast?.title ?? "Podcast")",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        guard let podcast else { 
            return .result(dialog: "No podcast was specified")
        }

        // Find the podcast in the database
        guard let podcastToFollow = DataManager.sharedManager.findPodcast(uuid: podcast.id, includeUnsubscribed: true) else {
            return .result(dialog: "Could not find podcast \(podcast.title)")
        }

        // Check if already subscribed
        if podcastToFollow.subscribed == 1 {
            return .result(dialog: "You are already following \(podcast.title)")
        }

        // Subscribe to the podcast
        podcastToFollow.subscribe()

        return .result(dialog: "Now following \(podcast.title)")
    }
}
