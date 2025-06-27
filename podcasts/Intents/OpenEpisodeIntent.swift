import Foundation
import AppIntents
import PocketCastsDataModel

struct OpenEpisode: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJOpenEpisodeIntent"

    static var title: LocalizedStringResource = "Open Episode"
    static var description = IntentDescription("Open Episode")

    static let openAppWhenRun = true

    @Parameter(title: "Episode")
    var episode: EpisodeSearchEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$episode)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$episode)) { episode in
            DisplayRepresentation(
                title: "Open \(episode?.title ?? "Episode")",
                subtitle: ""
            )
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let episode {
            userActivity.title = "Open \(episode.title)"
            userActivity.suggestedInvocationPhrase = "Open \(episode.title)"
            userActivity.userInfo = ["episodeUuid": episode.id]
        } else {
            userActivity.title = "Open Episode"
            userActivity.suggestedInvocationPhrase = "Open Episode"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.becomeCurrent()

        guard let episode else { return .result() }

        // Find the actual episode from the database
        guard let dbEpisode = DataManager.sharedManager.findEpisode(uuid: episode.id) else {
            return .result()
        }

        await MainActor.run {
            NavigationManager.sharedManager.navigateTo(
                NavigationManager.episodePageKey,
                data: [NavigationManager.episodeUuidKey: dbEpisode.uuid]
            )
        }

        return .result()
    }
}
