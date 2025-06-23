import Foundation
import AppIntents
import PocketCastsDataModel
import PocketCastsServer

struct OpenPodcast: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "SJOpenPodcastIntent"

    static var title: LocalizedStringResource = "Open Podcast"
    static var description = IntentDescription("Open Podcast")

    static let openAppWhenRun = true

    @Parameter(title: "Podcast")
    var podcast: PodcastEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$podcast)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$podcast)) { podcast in
            DisplayRepresentation(
                title: "Open \(podcast?.title ?? "Podcast")",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        let userActivity = NSUserActivity(activityType: "au.com.shiftyjelly.podcasts")

        userActivity.isEligibleForSearch = true
        if let podcast {
            userActivity.title = "Open \(podcast.title)"
            userActivity.suggestedInvocationPhrase = "Open \(podcast.title)"
            userActivity.userInfo = ["podcastUuid": podcast.id]
        } else {
            userActivity.title = "Open Podcast"
            userActivity.suggestedInvocationPhrase = "Open Podcast"
        }
        userActivity.isEligibleForPrediction = true
        userActivity.becomeCurrent()

        guard let podcast else { return .result() }
//        let podcastHeader = PodcastHeader(uuid: podcast.id)

        await MainActor.run {
            UIApplication.shared.open(URL(string: "pktc://shortcuts/podcast/\(podcast.id)")!)
//            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastHeader])
        }

        return .result()
    }
}
