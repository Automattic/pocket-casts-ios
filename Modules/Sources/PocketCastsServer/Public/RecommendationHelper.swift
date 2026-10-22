import Foundation
import PocketCastsDataModel

public class RecommendationHelper {
    public init() {}

    public func recommendEpisode() -> Episode? {
        if !SyncManager.isUserLoggedIn() {
            return nil
        }

        let recommendTask = RecommendEpisodesTask()
        var episode: Episode?
        recommendTask.completion = { recommendedEpisode in
            episode = recommendedEpisode
        }
        recommendTask.runTaskSynchronously()

        return episode
    }
}
