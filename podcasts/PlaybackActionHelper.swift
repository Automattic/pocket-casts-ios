import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PlaybackActionHelper {
    class func play(episode: BaseEpisode, filterUuid: String? = nil, podcastUuid: String? = nil) {
        HapticsHelper.triggerPlayPauseHaptic()

        AutoplayHelper.shared.savePlaylist()

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
