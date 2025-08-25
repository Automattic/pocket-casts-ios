import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class UpNextHistoryModel: ObservableObject {
    @Published var historyEntries: [UpNextHistoryManager.UpNextHistoryEntry] = []
    @Published var episodes: [BaseEpisode] = []

    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    @MainActor
    func loadEntries() {
        Task {
            historyEntries = dataManager.upNextHistoryEntries()
        }
    }

    @MainActor
    func loadEpisodes(for entry: Date) {
        Task {
            let episodesUuid = dataManager.upNextHistoryEpisodes(entry: entry)
            episodes = episodesUuid.compactMap { dataManager.findBaseEpisode(uuid: $0.episodeUuid) }
        }
    }

    func reAddMissingItems(entry: Date) {
        Task {
            let episodes = dataManager.upNextHistoryEpisodes(entry: entry)
            FileLog.shared.addMessage("UpNextHistory: Restoring entries from \(entry) with episodes: [\(episodes.map(\.episodeUuid).joined(separator: ","))]")

            episodes.forEach { entry in
                if let episode = dataManager.findBaseEpisode(uuid: entry.episodeUuid) {
                    PlaybackManager.shared.addToUpNext(episode: episode, userInitiated: false)
                } else {
                    if let episode = ServerPodcastManager.shared.addMissingEpisode(episodeUuid: entry.episodeUuid, podcastUuid: entry.podcastUuid) {
                        PlaybackManager.shared.addToUpNext(episode: episode, userInitiated: false)
                    } else {
                        assertionFailure("Couldn't find or restore episode \(entry.episodeUuid) for podcast \(entry.podcastUuid)")
                        FileLog.shared.addMessage("UpNextHistory: Couldn't find or restore episode \(entry.episodeUuid) for podcast \(entry.podcastUuid)")
                    }
                }
            }

            PlaybackManager.shared.queue.bulkOperationDidComplete()
            PlaybackManager.shared.queue.refreshList(checkForAutoDownload: false)
        }
    }
}
