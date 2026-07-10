import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension PodcastManager {
    func deletePodcastIfUnused(_ podcast: Podcast) async {
        // we don't delete podcasts that haven't been synced or you're still subscribed to
        if podcast.syncStatus == SyncStatus.notSynced.rawValue || podcast.isSubscribed() { return }

        // we don't delete podcasts added to the phone in the last week. This is to prevent stuff you just leave open in discover from being removed
        if let addedDate = podcast.addedDate, abs(addedDate.timeIntervalSinceNow) < 1.week { return }

        // we don't delete podcasts which have any episodes in a playlist or Up Next
        if dataManager.playlistContainsPodcast(podcastUuid: podcast.uuid) { return }

        let interactedEpisodes = dataManager.allEpisodesForPodcast(id: podcast.id).filter { $0.userHasInteractedWithEpisode() }

        // we can safely delete podcasts where the user hasn't interacted with any of the episodes
        if interactedEpisodes.isEmpty {
            let episodes = dataManager.allEpisodesForPodcast(id: podcast.id)
            await downloadManager.cancelTasks(for: episodes)

            // Delete all the episodes for the podcast that we're deleting
            dataManager.deleteAllEpisodesInPodcast(podcastId: podcast.id)
            dataManager.delete(podcast: podcast)
        }
    }

    func deleteGhostEpisodesIfNeeded() {
        let episodes = dataManager.findGhostEpisodes()
        guard !episodes.isEmpty else {
            return
        }

        FileLog.shared.addMessage("Found \(episodes.count) Ghost Episodes")

        var deleted_count = 0
        var uuids: [String] = []

        episodes.forEach { episode in
            guard
                !episode.uuid.isEmpty,
                episode.userHasInteractedWithEpisode() == false
            else {
                return
            }

            uuids.append("'\(episode.uuid)'")
            deleted_count += 1
        }

        DataManager.sharedManager.deleteGhostsEpisodes(uuids: uuids)
        FileLog.shared.addMessage("Deleted \(deleted_count) Ghost Episodes")
    }

    func deleteOrphanedEpisodesIfNeeded() {
        let orphans = dataManager.findOrphanedEpisodes()
        guard !orphans.isEmpty else {
            return
        }

        FileLog.shared.addMessage("Found \(orphans.count) Orphaned Episodes")

        var deletedCount = 0

        for (uuid, orphanRows) in Dictionary(grouping: orphans, by: \.uuid) {
            // Only act when there's exactly one unambiguous "live" row (valid podcast_id) to reconcile
            // against; anything else is a different/rarer shape of duplicate and is left alone.
            let liveRows = dataManager.findEpisodesWhere(customWhere: "uuid = ? AND podcast_id IN (SELECT id FROM \(DataManager.podcastTableName))", arguments: [uuid])
            guard liveRows.count == 1, let live = liveRows.first else {
                continue
            }

            let survivor = orphanRows
                .filter { $0.userHasInteractedWithEpisode() }
                .max { ($0.lastPlaybackInteractionDate ?? $0.addedDate ?? .distantPast) < ($1.lastPlaybackInteractionDate ?? $1.addedDate ?? .distantPast) }

            if let survivor {
                // The orphan already holds the real state (podcastUuid is still correct, only
                // podcast_id is dangling), so repoint it at the real podcast instead of copying
                // its fields onto the stale, pristine "live" row. Repoint + delete happen in one
                // write so a crash mid-migration can't commit one without the other.
                let otherOrphanIds = orphanRows.filter { $0.id != survivor.id }.map(\.id)
                dataManager.reconcileOrphanedEpisode(survivorId: survivor.id, realPodcastId: live.podcast_id, idsToDelete: [live.id] + otherOrphanIds)
                deletedCount += 1 + otherOrphanIds.count
            } else {
                dataManager.deleteOrphanedEpisodes(ids: orphanRows.map(\.id))
                deletedCount += orphanRows.count
            }
        }

        FileLog.shared.addMessage("Deleted \(deletedCount) Orphaned Episodes")
    }

    func checkForUnusedPodcasts() async {
        let podcasts = dataManager.allUnsubscribedPodcasts()
        for podcast in podcasts {
            await deletePodcastIfUnused(podcast)
        }
    }

    func checkForExpiredPodcastsAndCleanup() {
        let allPaidPodcasts = dataManager.allPaidPodcasts()

        let licenseRestrictedPodcasts = allPaidPodcasts.filter { $0.licensing == PodcastLicensing.deleteEpisodesAfterExpiry.rawValue }
        if licenseRestrictedPodcasts.isEmpty { return }

        for podcast in licenseRestrictedPodcasts {
            guard let subscription = SubscriptionHelper.subscriptionForPodcast(uuid: podcast.uuid) else { continue }

            let expiryDate = Date(timeIntervalSince1970: subscription.expiryDate)
            if expiryDate.timeIntervalSinceNow < 0, !subscription.autoRenewing {
                let downloadedEpisodes = dataManager.findEpisodesWhere(customWhere: "podcast_id == ? AND episodeStatus == ?", arguments: [podcast.id, DownloadStatus.downloaded.rawValue])
                for episode in downloadedEpisodes {
                    FileLog.shared.addMessage("Deleting downloaded episode \(episode.title ?? "No Title"), licensing expired")

                    PlaybackManager.shared.removeIfPlayingOrQueued(episode: episode, fireNotification: false)
                    downloadManager.removeFromQueue(episode: episode, fireNotification: false, userInitiated: false)
                    EpisodeManager.deleteDownloadedFiles(episode: episode)
                }
            }
        }
    }
}
