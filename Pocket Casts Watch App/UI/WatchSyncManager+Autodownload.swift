import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
extension WatchSyncManager {
    func checkForUpNextAutoDownloads() {
        guard isPlusUser() else {
            return
        }

        let autodownloadCount = WatchDataManager.upNextAutoDownloadCount()
        let allQueued = PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: true)

        guard autodownloadCount > 0, allQueued.count > 0 else {
            return
        }

        let maxDownloads = min(autodownloadCount, allQueued.count - 1)

        let autoDownloadCandidates = allQueued[0 ... maxDownloads]

        let downloadedEpisodes = DataManager.sharedManager.findDownloadedEpisodes()

        let deleteCandidates = downloadedEpisodes.filter { $0.autoDownloadStatus == AutoDownloadStatus.autoDownloaded.rawValue }

        for delete in deleteCandidates {
            if let upNextPosition = allQueued.firstIndex(where: { $0.uuid == delete.uuid }), upNextPosition < WatchDataManager.upNextAutoDeleteCount() {
                continue
            }
            EpisodeManager.deleteDownloadedFiles(episode: delete)
        }

        var count = 0
        for episode in autoDownloadCandidates {
            if episode.queued() || episode.downloaded(pathFinder: DownloadManager.shared) || episode.downloading() { continue }
            DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: true, autoDownloadStatus: .autoDownloaded)
            count += 1
        }
    }
}
