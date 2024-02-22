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
