import PocketCastsDataModel
import WatchKit
import PocketCastsUtils

enum WatchDataManager {
    static func playlists() -> [WatchPlaylist]? {
        if let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let filters = data[WatchConstants.Keys.filters] as? [[String: Any]] {
            var convertedFilters = [WatchPlaylist]()
            for filter in filters {
                let convertedFilter = WatchPlaylist()
                if let title = filter[WatchConstants.Keys.filterTitle] as? String {
                    convertedFilter.title = title
                }
                if let iconName = filter[WatchConstants.Keys.filterIcon] as? String {
                    convertedFilter.iconName = iconName
                }
                if let uuid = filter[WatchConstants.Keys.filterUuid] as? String {
                    convertedFilter.uuid = uuid
                }

                convertedFilters.append(convertedFilter)
            }

            return convertedFilters
        }

        return nil
    }

    static func upNextEpisodes() -> [BaseEpisode]? {
        if let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let upNextEpisodes = data[WatchConstants.Keys.upNextInfo] as? [[String: Any]] {
            var convertedEpisodes = [BaseEpisode]()
            for episode in upNextEpisodes {
                if let convertedEpisode = convertToEpisode(json: episode) {
                    convertedEpisodes.append(convertedEpisode)
                }
            }

            return convertedEpisodes
        }

        return nil
    }

    static func playingEpisode() -> BaseEpisode? {
        if let episodeJson = nowPlayingValue(key: WatchConstants.Keys.nowPlayingEpisode) as? [String: Any] {
            return convertToEpisode(json: episodeJson)
        }

        return nil
    }

    static func episodeIfAvailable(uuid: String) -> BaseEpisode? {
        if let playingEpisode = playingEpisode(), playingEpisode.uuid == uuid {
            return playingEpisode
        }

        if let upNextEpisodes = upNextEpisodes() {
            for episode in upNextEpisodes {
                if episode.uuid == uuid {
                    return episode
                }
            }
        }

        return nil
    }

    static func isPlaying() -> Bool {
        guard let playingStatus = nowPlayingValue(key: WatchConstants.Keys.nowPlayingStatus) as? String else { return false }

        return WatchConstants.PlayingStatus.playing == playingStatus
    }

    static func currentTime() -> TimeInterval {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingCurrentTime) as? TimeInterval ?? 0
    }

    static func nowPlayingPlayedUpToModified() -> Int64 {
        (nowPlayingValue(key: WatchConstants.Keys.nowPlayingPlayedUpToModified) as? NSNumber)?.int64Value ?? 0
    }

    static func duration() -> TimeInterval {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingDuration) as? TimeInterval ?? 0
    }

    static func skipBackAmount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSkipBackAmount) as? Int ?? 10
    }

    static func skipForwardAmount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSkipForwardAmount) as? Int ?? 45
    }

    static func playingEpisodeHasChapters() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingHasChapters) as? Bool ?? false
    }

    static func playbackSpeed() -> Double {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSpeed) as? Double ?? 1.0
    }

    static func nowPlayingChapterTitle() -> String {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingChapterTitle) as? String ?? ""
    }

    static func trimSilenceEnabled() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingTrimSilence) as? Bool ?? false
    }

    static func volumeBoostEnabled() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingVolumeBoost) as? Bool ?? false
    }

    static func nowPlayingColor() -> UIColor? {
        guard let color = nowPlayingValue(key: WatchConstants.Keys.nowPlayingColor) as? String else { return nil }

        return UIColor(hex: color)
    }

    static func nowPlayingSubTitle() -> String? {
        guard let title = nowPlayingValue(key: WatchConstants.Keys.nowPlayingSubtitle) as? String else { return nil }

        return title
    }

    static func upNextCount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingUpNextCount) as? Int ?? 0
    }

    private static func nowPlayingValue(key: String) -> Any? {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let playingInfo = data[WatchConstants.Keys.nowPlayingInfo] as? [String: Any] else { return nil }

        return playingInfo[key]
    }

    static func convertToEpisode(json: [String: Any]) -> BaseEpisode? {
        guard let type = json[WatchConstants.Keys.episodeTypeKey] as? String, let episodeMap = json[WatchConstants.Keys.episodeSerialisedKey] as? [String: String] else {
            return nil
        }

        if type == "Episode" {
            let episode = Episode()
            episode.populateFromMap(episodeMap)

            return episode
        } else {
            let userEpisode = UserEpisode()
            userEpisode.populateFromMap(episodeMap)

            return userEpisode
        }
    }

    static func convertToEpisodeList(data: [String: Any]) -> [BaseEpisode] {
        var episodes = [BaseEpisode]()

        if let allEpisodes = data[WatchConstants.Messages.FilterResponse.episodes] as? [[String: Any]] {
            for episodeData in allEpisodes {
                if let episode = WatchDataManager.convertToEpisode(json: episodeData) {
                    episodes.append(episode)
                }
            }
        }

        return episodes
    }

    static func upNextAutoDownloadCount() -> Int {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let downloadCount = data[WatchConstants.Keys.upNextDownloadEpisodeCount] as? Int else {
            return 0
        }
        return downloadCount
    }

    static func upNextAutoDeleteCount() -> Int {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let deleteCount = data[WatchConstants.Keys.upNextAutoDeleteEpisodeCount] as? Int else {
            return 25
        }
        return deleteCount
    }

    static func updateLastDataTime(to date: Date = Date()) {
        if FeatureFlag.watchUpNextSyncFix.enabled {
            UserDefaults.standard.set(date, forKey: WatchConstants.UserDefaults.lastDataTime)
        }
    }

    static func lastDataTime() -> Date {
        guard let lastTime = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.lastDataTime) as? Date else {
            return Date.distantPast
        }
        return lastTime
    }
}
