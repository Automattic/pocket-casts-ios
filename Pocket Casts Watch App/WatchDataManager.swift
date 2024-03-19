import PocketCastsDataModel
import WatchKit

class WatchDataManager {
    class func filters() -> [WatchFilter]? {
        if let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let filters = data[WatchConstants.Keys.filters] as? [[String: Any]] {
            var convertedFilters = [WatchFilter]()
            for filter in filters {
                let convertedFilter = WatchFilter()
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

    class func upNextEpisodes() -> [BaseEpisode]? {
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

    class func playingEpisode() -> BaseEpisode? {
        if let episodeJson = nowPlayingValue(key: WatchConstants.Keys.nowPlayingEpisode) as? [String: Any] {
            return convertToEpisode(json: episodeJson)
        }

        return nil
    }

    class func episodeIfAvailable(uuid: String) -> BaseEpisode? {
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

    class func isPlaying() -> Bool {
        guard let playingStatus = nowPlayingValue(key: WatchConstants.Keys.nowPlayingStatus) as? String else { return false }

        return WatchConstants.PlayingStatus.playing == playingStatus
    }

    class func currentTime() -> TimeInterval {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingCurrentTime) as? TimeInterval ?? 0
    }

    class func duration() -> TimeInterval {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingDuration) as? TimeInterval ?? 0
    }

    class func skipBackAmount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSkipBackAmount) as? Int ?? 10
    }

    class func skipForwardAmount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSkipForwardAmount) as? Int ?? 45
    }

    class func playingEpisodeHasChapters() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingHasChapters) as? Bool ?? false
    }

    class func playbackSpeed() -> Double {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingSpeed) as? Double ?? 1.0
    }

    class func nowPlayingChapterTitle() -> String {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingChapterTitle) as? String ?? ""
    }

    class func trimSilenceEnabled() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingTrimSilence) as? Bool ?? false
    }

    class func volumeBoostEnabled() -> Bool {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingVolumeBoost) as? Bool ?? false
    }

    class func nowPlayingColor() -> UIColor? {
        guard let color = nowPlayingValue(key: WatchConstants.Keys.nowPlayingColor) as? String else { return nil }

        return UIColor(hex: color)
    }

    class func nowPlayingSubTitle() -> String? {
        guard let title = nowPlayingValue(key: WatchConstants.Keys.nowPlayingSubtitle) as? String else { return nil }

        return title
    }

    class func upNextCount() -> Int {
        nowPlayingValue(key: WatchConstants.Keys.nowPlayingUpNextCount) as? Int ?? 0
    }

    private class func nowPlayingValue(key: String) -> Any? {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let playingInfo = data[WatchConstants.Keys.nowPlayingInfo] as? [String: Any] else { return nil }

        return playingInfo[key]
    }

    class func convertToEpisode(json: [String: Any]) -> BaseEpisode? {
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

    class func convertToEpisodeList(data: [String: Any]) -> [BaseEpisode] {
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

    class func upNextAutoDownloadCount() -> Int {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let downloadCount = data[WatchConstants.Keys.upNextDownloadEpisodeCount] as? Int else {
            return 0
        }
        return downloadCount
    }

    class func upNextAutoDeleteCount() -> Int {
        guard let data = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.data) as? [String: Any], let deleteCount = data[WatchConstants.Keys.upNextAutoDeleteEpisodeCount] as? Int else {
            return 25
        }
        return deleteCount
    }

    class func lastDataTime() -> Date {
        guard let lastTime = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.lastDataTime) as? Date else {
            return Date.distantPast
        }
        return lastTime
    }
}
