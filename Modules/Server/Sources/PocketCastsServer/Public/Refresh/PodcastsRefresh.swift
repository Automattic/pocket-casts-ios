import Foundation
import PocketCastsDataModel

class PodcastsRefresh {
    func refresh(podcasts: [Podcast], completion: (() -> Void)? = nil) async {
        let body: [String: Any] = ["podcasts": podcasts.map { ["uuid": $0.uuid, "last_modified": $0.lastUpdatedAt ?? ""] }]
        let startedDate = Date()
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

        try? await withThrowingTaskGroup(of: Void.self) { group in
            for podcast in result.podcasts {
                group.addTask {
                    await try? await JSONDecodableURLTask<FullPodcast>().post(urlString: podcast.url, body: body)
                }
            }

            try await group.waitForAll()
        }

        let elapsed = Date().timeIntervalSince(startedDate)
        print("$$ Request took \(elapsed)")
    }
}

struct ModifiedPodcastsEnvelope: Decodable {
    let podcasts: [ModifiedPodcast]
}

struct ModifiedPodcast: Decodable {
    let uuid: String
    let url: String
}
