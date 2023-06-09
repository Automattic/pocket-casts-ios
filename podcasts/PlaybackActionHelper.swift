import Foundation
import DifferenceKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PlaybackActionHelper {
    class func play(episode: BaseEpisode, filterUuid: String? = nil, podcastUuid: String? = nil) {
        HapticsHelper.triggerPlayPauseHaptic()

        let topViewController = AnalyticsCoordinator().getTopViewController() as? Autoplay
        let source = topViewController?.provider

        DatabaseQueries.playedFrom = source

        if GoogleCastManager.sharedManager.connectedOrConnectingToDevice() {
            PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
            return
        }

        if !episode.downloaded(pathFinder: DownloadManager.shared) {
            NetworkUtils.shared.streamEpisodeRequested({
                performPlay(episode: episode, filterUuid: filterUuid, podcastUuid: podcastUuid)
            }, disallowed: nil)
        } else {
            performPlay(episode: episode, filterUuid: filterUuid, podcastUuid: podcastUuid)
        }
    }

    class func pause() {
        HapticsHelper.triggerPlayPauseHaptic()
        PlaybackManager.shared.pause()
    }

    class func playPause() {
        HapticsHelper.triggerPlayPauseHaptic()
        PlaybackManager.shared.playPause()
    }

    class func download(episodeUuid: String) {
        AnalyticsEpisodeHelper.shared.downloaded(episodeUUID: episodeUuid)

        NetworkUtils.shared.downloadEpisodeRequested(autoDownloadStatus: .notSpecified, { later in
            if later {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episodeUuid, fireNotification: true, autoDownloadStatus: .notSpecified)
            } else {
                DownloadManager.shared.addToQueue(episodeUuid: episodeUuid)
            }
        }, disallowed: nil)
    }

    class func stopDownload(episodeUuid: String) {
        DownloadManager.shared.removeFromQueue(episodeUuid: episodeUuid, fireNotification: true, userInitiated: true)

        AnalyticsEpisodeHelper.shared.downloadCancelled(episodeUUID: episodeUuid)
    }

    class func overrideWaitingForWifi(episodeUuid: String, autoDownloadStatus: AutoDownloadStatus) {
        NetworkUtils.shared.downloadEpisodeRequested(autoDownloadStatus: autoDownloadStatus, { later in
            if later {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episodeUuid, fireNotification: true, autoDownloadStatus: autoDownloadStatus)
            } else {
                DownloadManager.shared.addToQueue(episodeUuid: episodeUuid)
            }
        }, disallowed: nil)
    }

    class func upload(episodeUuid: String) {
        NetworkUtils.shared.uploadEpisodeRequested({ later in
            if later {
                UploadManager.shared.queueForLaterUpload(episodeUuid: episodeUuid, fireNotification: true)
            } else {
                UploadManager.shared.addToQueue(episodeUuid: episodeUuid)
            }
        }, disallowed: nil)

        AnalyticsEpisodeHelper.shared.episodeUploaded(episodeUUID: episodeUuid)
    }

    class func stopUpload(episodeUuid: String) {
        UploadManager.shared.removeFromQueue(episodeUuid: episodeUuid, fireNotification: true)
        AnalyticsEpisodeHelper.shared.episodeUploadCancelled(episodeUUID: episodeUuid)
    }

    private class func performPlay(episode: BaseEpisode, filterUuid: String? = nil, podcastUuid: String? = nil) {
        if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.uuid) {
            PlaybackManager.shared.play()
        } else {
            if episode.archived, let episode = episode as? Episode {
                DataManager.sharedManager.saveEpisode(archived: false, episode: episode, updateSyncFlag: SyncManager.isUserLoggedIn())
            }

            if episode is Episode { // only record play stats for Episodes, not UserEpisodes
                AnalyticsHelper.playedEpisode()
            }

            // if we're streaming an episode, try to make sure the URL is up to date. Authors can change URLs at any time, so this is handy to fix cases where they post the wrong one and update it later
            if let episode = episode as? Episode, let podcast = episode.parentPodcast(), !episode.downloaded(pathFinder: DownloadManager.shared) {
                ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { wasUpdated in
                    guard let updatedEpisode = wasUpdated ? DataManager.sharedManager.findEpisode(uuid: episode.uuid) : episode else { return }

                    PlaybackManager.shared.load(episode: updatedEpisode, autoPlay: true, overrideUpNext: false)
                }
            } else {
                PlaybackManager.shared.load(episode: episode, autoPlay: true, overrideUpNext: false)
            }
        }

        if let filterUuid = filterUuid {
            SiriShortcutsManager.shared.donateFilterPlayed(filterUuid: filterUuid)
        } else if let podcastUuid = podcastUuid {
            SiriShortcutsManager.shared.donatePodcastPlayed(podcastUuid: podcastUuid)
        }
    }
}

class DatabaseQueries {
    enum Section {
        case podcast
        case download
        case listeningHistory
        case filter(uuid: String)
        case starred
        case files
    }

    static let shared = DatabaseQueries()

    static var playedFrom: Section? = nil

    private init() { }

    func downloadedEpisodes() -> [ArraySection<String, ListEpisode>] {
        let query = "( (downloadTaskId IS NOT NULL OR episodeStatus = \(DownloadStatus.downloaded.rawValue) OR episodeStatus = \(DownloadStatus.waitingForWifi.rawValue)) OR (episodeStatus = \(DownloadStatus.downloadFailed.rawValue) AND lastDownloadAttemptDate > ?) ) ORDER BY lastDownloadAttemptDate DESC LIMIT 1000"
        let arguments = [Date().weeksAgo(1)] as [Any]

        let newData = EpisodeTableHelper.loadSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: query, arguments: arguments, episodeShortKey: { episode -> String in
            episode.shortLastDownloadAttemptDate()
        })

        return newData
    }

    func listeningHistoryEpisodes() -> [ArraySection<String, ListEpisode>] {
        let query = "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000"

        let newData = EpisodeTableHelper.loadSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: query, arguments: nil, episodeShortKey: { episode -> String in
            episode.shortLastPlaybackInteractionDate()
        })

        return newData
    }

    func filterEpisodes(_ filter: EpisodeFilter) -> [ListEpisode] {
        let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.maxFilterItems)
        let tintColor = filter.playlistColor()
        return EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: query, arguments: nil)
    }

    func podcastEpisodes(_ podcast: Podcast, uuidsToFilter: [String]? = nil) -> [ArraySection<String, ListItem>] {
        let searchHeader = ListHeader(headerTitle: L10n.search, isSectionHeader: true)
        var newData = [ArraySection<String, ListItem>(model: searchHeader.headerTitle, elements: [searchHeader])]

        // Podcast screen query ArraySection<String, ListItem>
        let tintColor = AppTheme.appTintColor()
        let sortOrder = PodcastEpisodeSortOrder(rawValue: podcast.episodeSortOrder) ?? .newestToOldest
        switch podcast.podcastGrouping() {
        case .none:
            let episodes = EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil)
            newData.append(ArraySection(model: "episodes", elements: episodes))
        case .season:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, name2 -> Bool in
                sortOrder == .newestToOldest ? name1.digits > name2.digits : name2.digits > name1.digits
            }, episodeShortKey: { episode -> String in
                episode.seasonNumber > 0 ? L10n.podcastSeasonFormat(episode.seasonNumber.localized()) : L10n.podcastNoSeason
            })
            newData.append(contentsOf: groupedEpisodes)
        case .unplayed:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusUnplayed
            }, episodeShortKey: { episode -> String in
                episode.played() ? L10n.statusPlayed : L10n.statusUnplayed
            })
            newData.append(contentsOf: groupedEpisodes)
        case .downloaded:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusDownloaded
            }, episodeShortKey: { (episode: Episode) -> String in
                episode.downloaded(pathFinder: DownloadManager.shared) || episode.queued() || episode.downloading() ? L10n.statusDownloaded : L10n.statusNotDownloaded
            })
            newData.append(contentsOf: groupedEpisodes)
        case .starred:
            let groupedEpisodes = EpisodeTableHelper.loadSortedSectionedEpisodes(tintColor: AppTheme.appTintColor(), query: createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter), arguments: nil, sectionComparator: { name1, _ -> Bool in
                name1 == L10n.statusStarred
            }, episodeShortKey: { episode -> String in
                episode.keepEpisode ? L10n.statusStarred : L10n.statusNotStarred
            })
            newData.append(contentsOf: groupedEpisodes)
        }

        return newData
    }

    private func createEpisodesQuery(_ podcast: Podcast, uuidsToFilter: [String]? = nil) -> String {
        let sortStr: String
        let sortOrder = PodcastEpisodeSortOrder(rawValue: podcast.episodeSortOrder) ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .newestToOldest:
            sortStr = "ORDER BY publishedDate DESC, addedDate DESC"
        case .oldestToNewest:
            sortStr = "ORDER BY publishedDate ASC, addedDate ASC"
        case .shortestToLongest:
            sortStr = "ORDER BY duration ASC, addedDate"
        case .longestToShortest:
            sortStr = "ORDER BY duration DESC, addedDate"
        }
        if let uuids = uuidsToFilter {
            let inClause = "(\(uuids.map { "'\($0)'" }.joined(separator: ",")))"
            return "podcast_id = \(podcast.id) AND uuid IN \(inClause) \(sortStr)"
        }
        if !podcast.showArchived {
            return "podcast_id = \(podcast.id) AND archived = 0 \(sortStr)"
        }

        return "podcast_id = \(podcast.id) \(sortStr)"
    }

    func starredEpisodes() -> [ListEpisode] {
        let query = "keepEpisode = 1 ORDER BY starredModified DESC LIMIT 1000"
        let newData = EpisodeTableHelper.loadEpisodes(tintColor: AppTheme.appTintColor(), query: query, arguments: nil)

        return newData
    }

    func uploadedEpisodes() -> [UserEpisode] {
        let sortBy = UploadedSort(rawValue: Settings.userEpisodeSortBy()) ?? UploadedSort.newestToOldest

        var uploadedEpisodes: [UserEpisode]
        if SubscriptionHelper.hasActiveSubscription() {
            uploadedEpisodes = DataManager.sharedManager.allUserEpisodes(sortedBy: sortBy)
        } else {
            uploadedEpisodes = DataManager.sharedManager.allUserEpisodesDownloaded(sortedBy: sortBy)
        }

        return uploadedEpisodes
    }

    func getEpisodes() -> [BaseEpisode] {
        switch Self.playedFrom {
        case .files:
            return uploadedEpisodes().compactMap { $0 as BaseEpisode }
        case .listeningHistory:
            var episodes: [BaseEpisode] = []
            listeningHistoryEpisodes().forEach { episodes.append(contentsOf: $0.elements.map { $0.episode as BaseEpisode }) }
            return episodes
        case .filter(uuid: let uuid):
            if let filter = DataManager.sharedManager.findFilter(uuid: uuid) {
                return filterEpisodes(filter).compactMap { $0.episode }
            }
            return  []
        default:
            return []
        }
    }
}
