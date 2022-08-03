import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension PodcastManager {
    func deletePodcastIfUnused(_ podcast: Podcast) {
        // we don't delete podcasts that haven't been synced or you're still subscribed to
        if podcast.syncStatus == SyncStatus.notSynced.rawValue || podcast.isSubscribed() { return }
        
        // we don't delete podcasts added to the phone in the last week. This is to prevent stuff you just leave open in discover from being removed
        if let addedDate = podcast.addedDate, abs(addedDate.timeIntervalSinceNow) < 1.week { return }
        
        let interactedEpisodes = DataManager.sharedManager.allEpisodesForPodcast(id: podcast.id).filter { $0.userHasInteractedWithEpisode() }
        
        // we can safely delete podcasts where the user hasn't interacted with any of the episodes
        if interactedEpisodes.count == 0 {
            // Delete all the episodes for the podcast that we're deleting
            DataManager.sharedManager.deleteAllEpisodesInPodcast(podcastId: podcast.id)
            DataManager.sharedManager.delete(podcast: podcast)
        }
    }

    func deleteGhostEpisodesIfNeeded() {
        let episodes = DataManager.sharedManager.findGhostEpisodes()
        guard episodes.count != 0 else {
            return
        }

        FileLog.shared.addMessage("Found \(episodes.count) Ghost Episodes")
        
        var deleted_count = 0
        episodes.forEach { episode in
            guard
                episode.uuid.count != 0,
                episode.userHasInteractedWithEpisode() == false
            else {
                return
            }

            DataManager.sharedManager.delete(episodeUuid: episode.uuid)
            deleted_count += 1
        }

        FileLog.shared.addMessage("Deleted \(deleted_count) Ghost Episodes")
    }
    
    func checkForUnusedPodcasts() {
        let podcasts = DataManager.sharedManager.allUnsubscribedPodcasts()
        for podcast in podcasts {
            deletePodcastIfUnused(podcast)
        }
    }
    
    func checkForExpiredPodcastsAndCleanup() {
        let allPaidPodcasts = DataManager.sharedManager.allPaidPodcasts()
        
        let licenseRestrictedPodcasts = allPaidPodcasts.filter { $0.licensing == PodcastLicensing.deleteEpisodesAfterExpiry.rawValue }
        if licenseRestrictedPodcasts.count == 0 { return }
        
        for podcast in licenseRestrictedPodcasts {
            guard let subscription = SubscriptionHelper.subscriptionForPodcast(uuid: podcast.uuid) else { continue }
            
            let expiryDate = Date(timeIntervalSince1970: subscription.expiryDate)
            if expiryDate.timeIntervalSinceNow < 0, !subscription.autoRenewing {
                let downloadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "podcast_id == ? AND episodeStatus == ?", arguments: [podcast.id, DownloadStatus.downloaded.rawValue])
                for episode in downloadedEpisodes {
                    FileLog.shared.addMessage("Deleting downloaded episode \(episode.title ?? "No Title"), licensing expired")
                    
                    PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: false)
                    DownloadManager.shared.removeFromQueue(episode: episode, fireNotification: false, userInitiated: false)
                    EpisodeManager.deleteDownloadedFiles(episode: episode)
                }
            }
        }
    }
}
