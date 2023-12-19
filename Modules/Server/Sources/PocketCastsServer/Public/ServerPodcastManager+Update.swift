import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension ServerPodcastManager {

    /// Update a podcast if required.
    /// - Parameters:
    ///   - podcast: a `Podcast`
    ///   - addMissingEpisodes: if set to `true` it will add missing episodes that are not the latest ones.
    ///   Latest ones are handled by a refresh (due to auto-download/up next)
    ///   - completion: a completion block that receives a `Bool`
    public func updatePodcastIfRequired(podcast: Podcast, addMissingEpisodes: Bool = false, completion: ((Bool) -> Void)?) {
        CacheServerHandler.shared.loadPodcastIfModified(podcast: podcast) { [weak self] podcastInfo, lastModified in
            if let podcastInfo = podcastInfo {
                self?.updatePodcast(podcast: podcast, lastModified: lastModified, podcastInfo: podcastInfo, addMissingEpisodes: addMissingEpisodes, completion: {
                    FileLog.shared.addMessage("\(podcast.title ?? "") updated from cache server")
                    completion?(true)
                })
            } else {
                FileLog.shared.addMessage("\(podcast.title ?? "") didn't need to be updated from cache server")
                completion?(false)
            }
        }
    }

    public func updatePodcastIfRequired(podcast: Podcast) async -> Bool {
        await withCheckedContinuation { continuation in
            updatePodcastIfRequired(podcast: podcast) { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func updatePodcast(podcast: Podcast, lastModified: String?, podcastInfo: [String: Any], addMissingEpisodes: Bool, completion: (() -> Void)?) {
        subscribeQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.update(podcast: podcast, podcastInfo: podcastInfo, lastModified: lastModified, addMissingEpisodes: addMissingEpisodes)
            completion?()
        }
    }

    private func update(podcast: Podcast, podcastInfo: [String: Any], lastModified: String?, addMissingEpisodes: Bool) {
        guard let podcastJson = podcastInfo["podcast"] as? [String: Any], let episodesJson = podcastJson["episodes"] as? [[String: Any]] else { return }

        podcast.lastUpdatedAt = lastModified
        if let title = podcastJson["title"] as? String {
            podcast.title = title
        }
        if let author = podcastJson["author"] as? String {
            podcast.author = author
        }
        if let url = podcastJson["url"] as? String {
            podcast.podcastUrl = url
        }
        if let description = podcastJson["description"] as? String {
            podcast.podcastDescription = description
        }
        if let category = podcastJson["category"] as? String {
            podcast.podcastCategory = category
        }
        if let showType = podcastJson["show_type"] as? String {
            podcast.showType = showType
        }
        if let estimatedNextEpisode = podcastInfo["estimated_next_episode_at"] as? String {
            podcast.estimatedNextEpisode = isoFormatter.date(from: estimatedNextEpisode)
        }
        if let frequency = podcastInfo["episode_frequency"] as? String {
            podcast.episodeFrequency = frequency
        }
        if let paid = podcastJson["paid"] as? Int {
            podcast.isPaid = paid > 0
        }
        if let licensing = podcastJson["licensing"] as? Int {
            podcast.licensing = Int32(licensing)
        }
        if let refreshAvailable = podcastInfo["refresh_allowed"] as? Bool {
            podcast.refreshAvailable = refreshAvailable
        }

        DataManager.sharedManager.save(podcast: podcast)

        var latestEpisodeWasMissing: Bool?

        var missingEpisodesThatIsNotTheLatestOnes = false

        var latestAvailableEpisodeUuid: String?

        for episodeJson in episodesJson {
            guard let uuid = episodeJson["uuid"] as? String, let publishedStr = episodeJson["published"] as? String, let episodeDate = isoFormatter.date(from: publishedStr) else { continue }

            // for existing episodes, update the fields we want to pick up when they change
            if let existingEpisode = DataManager.sharedManager.findEpisode(uuid: uuid) {
                var episodeChanged = false
                if let title = episodeJson["title"] as? String, existingEpisode.title != title {
                    existingEpisode.title = title
                    episodeChanged = true
                }
                if let url = episodeJson["url"] as? String, url != existingEpisode.downloadUrl {
                    existingEpisode.downloadUrl = url
                    episodeChanged = true
                }
                if episodeDate != existingEpisode.publishedDate {
                    existingEpisode.publishedDate = episodeDate
                    episodeChanged = true
                }
                if let number = episodeJson["number"] as? Int64, existingEpisode.episodeNumber != number {
                    existingEpisode.episodeNumber = number
                    episodeChanged = true
                }
                if let season = episodeJson["season"] as? Int64, existingEpisode.seasonNumber != season {
                    existingEpisode.seasonNumber = season
                    episodeChanged = true
                }
                if let type = episodeJson["type"] as? String, existingEpisode.episodeType != type {
                    existingEpisode.episodeType = type
                    episodeChanged = true
                }

                if episodeChanged {
                    DataManager.sharedManager.save(episode: existingEpisode)
                }

                if latestEpisodeWasMissing == true {
                    latestAvailableEpisodeUuid = uuid
                }

                latestEpisodeWasMissing = false

                continue
            }

            // For subscribed podcasts, only add older episodes, newer ones are handled by a refresh
            // so stuff like auto-download, auto add to up next works as expected
            // However, if this is not a new episode we force update the podcast episodes
            if podcast.isSubscribed(), episodeDate.timeIntervalSinceNow >= podcast.latestEpisodeDate?.timeIntervalSinceNow ?? TimeInterval.greatestFiniteMagnitude {
                if latestEpisodeWasMissing == false {
                    missingEpisodesThatIsNotTheLatestOnes = true
                }

                latestEpisodeWasMissing = true
                continue
            }

            // if we get to here then we need to add this episode because we are missing it
            let episode = Episode()
            episode.addedDate = Date()
            episode.podcast_id = podcast.id
            episode.podcastUuid = podcast.uuid
            episode.playingStatus = PlayingStatus.notPlayed.rawValue
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            episode.uuid = uuid
            episode.lastArchiveInteractionDate = Date()
            episode.publishedDate = episodeDate
            // for podcast you're subscribed to, if we find episodes older than a week, we add them in as archived so they don't flood your filters, etc
            episode.archived = podcast.isSubscribed() && DateUtil.hasEnoughTimePassed(since: episodeDate, time: 7.days)
            if let title = episodeJson["title"] as? String {
                episode.title = title
            }
            if let url = episodeJson["url"] as? String {
                episode.downloadUrl = url
            }
            if let fileType = episodeJson["file_type"] as? String {
                episode.fileType = fileType
            }
            if let fileSize = episodeJson["file_size"] as? Int64 {
                episode.sizeInBytes = fileSize
            }
            if let duration = episodeJson["duration"] as? Double {
                episode.duration = duration
            }
            if let number = episodeJson["number"] as? Int64 {
                episode.episodeNumber = number
            }
            if let season = episodeJson["season"] as? Int64 {
                episode.seasonNumber = season
            }
            if let type = episodeJson["type"] as? String {
                episode.episodeType = type
            }

            DataManager.sharedManager.save(episode: episode)
        }

        if !podcast.isSubscribed() {
            ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: false)
        } else {
            // for subscribed podcasts remove any non-interacted with episodes that aren't in the server JSON
            cleanupDeletedEpisodes(podcast: podcast, serverEpisodes: episodesJson)
        }

        // If there are episode missing that are not the recent ones this mean that
        // likely this show changed the episodes dates. This might lead to some
        // episodes never being added, so we add them here
        if addMissingEpisodes, missingEpisodesThatIsNotTheLatestOnes, let latestAvailableEpisodeUuid {
            FileLog.shared.addMessage("[ServerPodcastManager] Updating \(podcast.title ?? "") from episode UUID \(latestAvailableEpisodeUuid)")
            RefreshManager.shared.refresh(podcast: podcast, from: latestAvailableEpisodeUuid)
        }
    }

    public func updateLatestEpisodeInfo(podcast: Podcast, setDefaults: Bool) {
        guard let latestEpisode = podcast.latestEpisode() else { return }

        // no need to re-save one we already have
        if !setDefaults, podcast.latestEpisodeUuid == latestEpisode.uuid { return }

        podcast.latestEpisodeDate = latestEpisode.publishedDate
        podcast.latestEpisodeUuid = latestEpisode.uuid
        DataManager.sharedManager.save(podcast: podcast)

        if setDefaults {
            setDefaultsAndLoadMetadataForNewlyAddedPodcast(podcast, latestEpisode: latestEpisode)
        }
    }

    private func setDefaultsAndLoadMetadataForNewlyAddedPodcast(_ podcast: Podcast, latestEpisode: Episode?) {
        // if all the podcasts the user currently has are auto download, set this one to be as well
        let autoDownloadQuery = "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE subscribed = 1 AND autoDownloadSetting = 1"
        let totalQuery = "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE subscribed = 1"

        let autoDownloadCount = DataManager.sharedManager.count(query: autoDownloadQuery, values: nil)
        let totalCount = (DataManager.sharedManager.count(query: totalQuery, values: nil) - 1) // -1 because the podcast we're currently adding could be returned by this query
        if totalCount > 0, autoDownloadCount >= totalCount {
            podcast.autoDownloadSetting = AutoDownloadSetting.latest.rawValue
            if let latestEpisode = latestEpisode {
                ServerConfig.shared.syncDelegate?.autoDownloadLatestEpisode(episode: latestEpisode)
            }
        } else {
            podcast.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        }

        podcast.episodeGrouping = ServerConfig.shared.syncDelegate?.defaultPodcastGrouping() ?? 0
        podcast.showArchived = ServerConfig.shared.syncDelegate?.defaultShowArchived() ?? false

        DataManager.sharedManager.save(podcast: podcast)
        DataManager.sharedManager.setPushDefaultForNewPodcast(podcast)
        #if !os(watchOS)
            if let latestEpisode = latestEpisode {
                MetadataUpdater.shared.updatedMetadata(episodeUuid: latestEpisode.uuid)
            }
        #endif
    }

    private func cleanupDeletedEpisodes(podcast: Podcast, serverEpisodes: [[String: Any]]) {
        // looks for episodes we have locally, that no longer exist online and that the user hasn't done anything with and deletes them
        let serverUuids = serverEpisodes.compactMap { $0["uuid"] as? String }.map { "\"\($0)\"" }
        if serverUuids.count == 0 { return } // don't clean up based on empty episodes results

        let inStr = serverUuids.joined(separator: ",")
        let nonServerEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "podcast_id == ? AND uuid NOT IN (\(inStr))", arguments: [podcast.id])
        for episode in nonServerEpisodes {
            guard ServerConfig.shared.syncDelegate?.episodeCanBeCleanedUp(episode: episode) == true else { continue }

            // don't cleanup episodes that are less than Constants.Values.oldEpisodeCutoff old (currently 2 weeks)
            if let publishedDate = episode.publishedDate, fabs(publishedDate.timeIntervalSinceNow) < ServerConstants.Values.oldEpisodeCutoff { continue }

            // this is an old episode we can safely blow away
            DataManager.sharedManager.delete(episodeUuid: episode.uuid)
        }
    }
}
