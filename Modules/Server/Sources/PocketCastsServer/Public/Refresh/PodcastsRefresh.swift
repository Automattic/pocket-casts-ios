import Foundation
import PocketCastsDataModel

class PodcastsRefresh {
    func refresh(podcasts: [Podcast], completion: (() -> Void)? = nil) async {
        let body: [String: Any] = ["podcasts": podcasts.map { ["uuid": $0.uuid, "last_modified": $0.lastUpdatedAt ?? ""] }]
        let result = try? await JSONDecodableURLTask<ModifiedPodcastsEnvelope>().post(urlString: "\(ServerConstants.Urls.cache())podcasts/update", body: body)

        guard let result else {
            return
        }

        let uuidsToUpdate = result.podcasts.map { $0.uuid }
        let podcastsToUpdate = podcasts.filter { uuidsToUpdate.contains($0.uuid) }

        guard !podcastsToUpdate.isEmpty else {
            print("nothing to update")
            return
        }

        let success = try? await withThrowingTaskGroup(of: Bool.self) { group in
            for podcast in podcastsToUpdate {
                group.addTask {
                    await ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast)
                }

                for try await success in group {
                    if !success {
                        return false
                    }
                }
            }

            return true
        }

        print("weeeeeeee \(success)")
    }
}

struct ModifiedPodcastsEnvelope: Decodable {
    let podcasts: [ModifiedPodcast]
}

struct ModifiedPodcast: Decodable {
    let uuid: String
    let url: String
}
