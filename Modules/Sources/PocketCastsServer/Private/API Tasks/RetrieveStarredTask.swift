import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveStarredTask: ApiBaseTask, @unchecked Sendable {
    var completion: (([Episode]?) -> Void)?

    private var convertedEpisodes = [Episode]()

    override func apiTokenAcquired(token: String) async {
        let url = ServerConstants.Urls.api() + "starred/list"

        do {
            let starredRequest = Api_EmptyRequest()
            let data = try starredRequest.serializedData()

            let (response, httpStatus) = await postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let serverEpisodes = try Api_StarredEpisodesResponse(serializedBytes: responseData).episodes
                if serverEpisodes.isEmpty {
                    completion?(convertedEpisodes)

                    return
                }

                for serverEpisode in serverEpisodes {
                    await processEpisode(serverEpisode)
                }

                completion?(convertedEpisodes)
            } catch {
                FileLog.shared.addMessage("Decoding starred failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("retrieve starred failed \(error.localizedDescription)")
            completion?(nil)
        }
    }

    private func processEpisode(_ protoEpisode: Api_StarredEpisode) async {
        // take the easy case first, do we have this episode locally?
        if convertLocalEpisode(protoEpisode: protoEpisode) {
            return
        }

        // we don't have the episode, see if we have the podcast
        if let podcast = DataManager.sharedManager.findPodcast(uuid: protoEpisode.podcastUuid, includeUnsubscribed: true) {
            // we do, so try and refresh it
            await withCheckedContinuation { continuation in
                ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { [weak self] updated in
                    if updated {
                        // the podcast was updated, try to convert the episode
                        self?.convertLocalEpisode(protoEpisode: protoEpisode)
                    }

                    continuation.resume()
                }
            }
        } else {
            // we don't, so try and add it
            await withCheckedContinuation { continuation in
                ServerPodcastManager.shared.addFromUuid(podcastUuid: protoEpisode.podcastUuid, subscribe: false) { [weak self] _ in
                    // this will convert the episode if we now have it, if we don't not much we can do
                    self?.convertLocalEpisode(protoEpisode: protoEpisode)
                    continuation.resume()
                }
            }
        }
    }

    @discardableResult
    private func convertLocalEpisode(protoEpisode: Api_StarredEpisode) -> Bool {
        guard let episode = DataManager.sharedManager.findEpisode(uuid: protoEpisode.uuid) else { return false }

        // star this episode in case it's not locally
        if !episode.keepEpisode || episode.starredModified != protoEpisode.starredModified {
            DataManager.sharedManager.saveEpisode(starred: true, starredModified: protoEpisode.starredModified, episode: episode, updateSyncFlag: false)
        }

        convertedEpisodes.append(episode)

        return true
    }
}
