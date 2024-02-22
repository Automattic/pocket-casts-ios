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

        // The URLSession has a max number of concurrent operations
        // Limit the number of requests we're making to that number to prevent bogging the system down
        let task = JSONDecodableURLTask<FullPodcastResponse>()
        let maxConcurrentTasks = URLSession.shared.configuration.httpMaximumConnectionsPerHost
        let podcasts = result.podcasts

        let parseStartDate = Date()
        do {
            let fullPodcasts = try await withThrowingTaskGroup(of: FullPodcast?.self) { group in
                for index in 0..<maxConcurrentTasks {
                    group.addTask {
                        try await task.get(urlString: podcasts[index].url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)?.podcast
                    }
                }

                var nextIndex = maxConcurrentTasks
                var result: [FullPodcast] = []

                for try await jsonResult in group {
                    if nextIndex < podcasts.count {
                        group.addTask { [nextIndex] in
                            try await task.get(urlString: podcasts[nextIndex].url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)?.podcast
                        }
                    }

                    nextIndex += 1
                    if let jsonResult {
                        result.append(jsonResult)
                    }
                }

                return result
            }

            try await save(podcasts: fullPodcasts)
        } catch {
            debugLog("Failed", error)
        }

        debugLog("$$ Episode Requests Took: \(Date().timeIntervalSince(parseStartDate))")
        debugLog("$$ Total Time: \(Date().timeIntervalSince(startedDate))")
    }

    // Tries to replicate the  some of the logic used in the RefreshOperation.performRefresh call
    func save(podcasts: [FullPodcast]) async throws {
        let total = podcasts.map { $0.episodes.count }.reduce(0, +)
        if #available(watchOS 8.0, *) {
            debugLog("$$ There are a total of: \(total.formatted()) episodes")
        }

        DataManager.sharedManager.inDatabase { database in
            let localPodcasts = try? DataManager.sharedManager.podcasts(uuids: podcasts.compactMap { $0.uuid }, in: database)

            for podcast in podcasts {
                // Reduce memory footprint while processing
                autoreleasepool {
                    guard
                        let podcastUuid = podcast.uuid,
                        let localPodcast = localPodcasts?.first(where: { $0.uuid == podcastUuid }),
                        let localEpisodes = try? DataManager.sharedManager.episodes(for: podcastUuid,
                                                                                    in: database).map({ $0.uuid })
                    else {
                        return
                    }

                    for incomingEpisode in podcast.episodes {
                        guard let uuid = incomingEpisode.uuid, localEpisodes.contains(uuid) == false else {
                            continue
                        }

                        let newEpisode = Episode()
                        newEpisode.podcast_id = localPodcast.id
                        newEpisode.podcastUuid = localPodcast.uuid
                        newEpisode.playingStatus = PlayingStatus.notPlayed.rawValue
                        newEpisode.episodeStatus = DownloadStatus.notDownloaded.rawValue
                        newEpisode.addedDate = Date()
                        newEpisode.populate(fromEpisode: incomingEpisode)
                        DataManager.sharedManager.save(episode: newEpisode, in: database)
                    }
                }
            }

            try await group.waitForAll()
        }

        let elapsed = Date().timeIntervalSince(startedDate)
        print("$$ Request took \(elapsed)")
    }
}

// MARK: - Debug

// Get the memory usage of the app
func memoryUsage() -> Float {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    let usedMb = Float(taskInfo.phys_footprint) / 1048576.0
    return result == KERN_SUCCESS ? usedMb : 0
}

// prints a log with some extra info attached
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(["ℹ️", "[\(memoryUsage()) mb]"] + items, separator: separator, terminator: terminator)
}


struct ModifiedPodcastsEnvelope: Decodable {
    let podcasts: [ModifiedPodcast]
}

struct ModifiedPodcast: Decodable {
    let uuid: String
    let url: String
}
