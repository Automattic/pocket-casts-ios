import Foundation
import PocketCastsDataModel

public class RecommendationHelper {
    public init() {}

    public func recommendEpisode() async -> Episode? {
        if !SyncManager.isUserLoggedIn() {
            return nil
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let recommendTask = RecommendEpisodesTask()
                var episode: Episode?
                recommendTask.completion = { recommendedEpisode in
                    episode = recommendedEpisode
                }
                recommendTask.runTaskSynchronously()

                continuation.resume(returning: episode)
            }
        }
    }
}
