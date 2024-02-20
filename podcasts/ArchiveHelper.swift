import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class ArchiveHelper {
    class func archiveTimeToText(_ time: TimeInterval) -> String {
        if time < 0 {
            return L10n.timeFormatNever.localizedCapitalized
        } else if time == 0 {
            return L10n.afterPlaying
        } else if time == 24.hours {
            return L10n.settingsAutoArchive24Hours
        } else if time == 2.days {
            return L10n.settingsAutoArchive2Days
        } else if time == 1.week {
            return L10n.settingsAutoArchive1Week
        } else if time == 2.weeks {
            return L10n.settingsAutoArchive2Weeks
        } else if time == 30.days {
            return L10n.settingsAutoArchive30Days
        } else if time == 90.days {
            return L10n.settingsAutoArchive3Months
        } else {
            return "TODO"
        }
    }

    class func applyAutoArchivingToPodcast(_ podcast: Podcast?) {
        guard let podcast = podcast else { return }

        let afterPlayedTime = podcast.isAutoArchiveOverridden ? podcast.autoArchivePlayedAfterTime : Settings.autoArchivePlayedAfter()
        let afterInactiveTime = podcast.isAutoArchiveOverridden ? podcast.autoArchiveInactiveAfterTime : Settings.autoArchiveInactiveAfter()
        let episodeLimit = podcast.isAutoArchiveOverridden ? podcast.autoArchiveEpisodeLimitCount : 0
        let archiveStarred = Settings.archiveStarredEpisodes()

        if afterPlayedTime > 0 {
            let playedRemoveTime = Date().addingTimeInterval(-afterPlayedTime)
            var playedRemoveQuery = "podcast_id == ? AND archived = 0 AND playingStatus = 3 AND lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate < ?"
            if !archiveStarred {
                playedRemoveQuery += " AND keepEpisode <> 1"
            }

            removeEpisodesMatchingQuery(playedRemoveQuery, arguments: [podcast.id, playedRemoveTime])
        }

        if afterInactiveTime > 0 {
            let inactiveRemoveTime = Date().addingTimeInterval(-afterInactiveTime)
            var inactiveRemoveQuery = "podcast_id = ? AND archived = 0 AND NOT (addedDate > ? OR (CASE WHEN lastPlaybackInteractionDate IS NULL THEN 0 ELSE lastPlaybackInteractionDate END) > ? OR lastDownloadAttemptDate > ? OR lastArchiveInteractionDate > ?)"
            if !archiveStarred {
                inactiveRemoveQuery += " AND keepEpisode <> 1"
            }
            removeEpisodesMatchingQuery(inactiveRemoveQuery, arguments: [podcast.id, inactiveRemoveTime, inactiveRemoveTime, inactiveRemoveTime, inactiveRemoveTime])
        }

        if episodeLimit > 0 {
            let currentlyPlayingUuid = PlaybackManager.shared.playing() ? PlaybackManager.shared.currentEpisode()?.uuid : nil
            let episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "podcast_id = ? ORDER BY publishedDate DESC, addedDate DESC", arguments: [podcast.id])
            for (index, episode) in episodes.enumerated() {
                if index < episodeLimit { continue }

                if episode.archived || episode.excludeFromEpisodeLimit || (!archiveStarred && episode.keepEpisode) || episode.uuid == currentlyPlayingUuid { continue }

                // if we get here we're past the episode limit, and the episode is un-archived and hasn't been excluded, so archive it
                EpisodeManager.archiveEpisode(episode: episode, fireNotification: false, userInitiated: false)
            }
        }
    }

    private class func removeEpisodesMatchingQuery(_ query: String, arguments: [Any]) {
        let removableEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: query, arguments: arguments)
        for episode in removableEpisodes {
            EpisodeManager.archiveEpisode(episode: episode, fireNotification: false, userInitiated: false)
        }
    }
}
