import Foundation
import PocketCastsDataModel

public class RecommendationHelper {
    public init() {}

    public func recommendEpisode(completion: @escaping ((Episode?) -> Void)) {
        if !SyncManager.isUserLoggedIn() {
            completion(nil)

            return
        }

        DispatchQueue.global().async {
            let recommendTask = RecommendEpisodesTask()
            recommendTask.completion = { episode in
                completion(episode)
            }
            recommendTask.runTaskSynchronously()
        }
    }

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
