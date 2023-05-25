import Foundation
import PocketCastsUtils
import UIKit

class CommonWidgetHelper {
    static let appGroupId = "group.au.com.shiftyjelly.pocketcasts"
    class func loadAppIconName() -> String {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let appIcon = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.appIcon) as? String else {
            return "AppIcon-Pride"
        }
        return appIcon
    }

    class func loadNowPlayingInfo() -> [CommonUpNextItem]? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let upNextData = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.upNextItems) as? Data else {
            return nil
        }

        do {
            let episodes = try JSONDecoder().decode([CommonUpNextItem].self, from: upNextData)
            return episodes
        } catch {
            return nil
        }
    }

    class func loadNowPlayingEpisode() -> WidgetEpisode? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId),
              let upNextData = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.upNextItems) as? Data,
              let firstEpisode = try? JSONDecoder().decode([CommonUpNextItem].self, from: upNextData).first
        else {
            return nil
        }

        return WidgetEpisode(commonItem: firstEpisode)
    }

    class func loadNowPlayingEpisodes() -> [WidgetEpisode]? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let upNextData = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.upNextItems) as? Data else {
            return nil
        }

        do {
            let episodes = try JSONDecoder().decode([CommonUpNextItem].self, from: upNextData)
            return topWidgetEpisodesFrom(episodes)
        } catch {
            return nil
        }
    }

    class func loadUpNextEpisodesCount() -> Int? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let upNextCount = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.upNextItemsCount) as? Int else {
            return nil
        }

        return upNextCount
    }

    class func loadTopFilterItems() -> [CommonUpNextItem]? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let filterData = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.topFilterItems) as? Data else {
            return nil
        }

        do {
            let episodes = try JSONDecoder().decode([CommonUpNextItem].self, from: filterData)
            return episodes
        } catch {
            return nil
        }
    }

    class func loadTopFilterEpisodes() -> [WidgetEpisode]? {
        guard let filterEpisodes = loadTopFilterItems() else { return nil }

        return topWidgetEpisodesFrom(filterEpisodes)
    }

    class func topWidgetEpisodesFrom(_ commonItems: [CommonUpNextItem]) -> [WidgetEpisode]? {
        guard commonItems.count > 0 else { return nil }

        let widgetEpisodes = commonItems.map { WidgetEpisode(commonItem: $0) }

        return Array(widgetEpisodes.prefix(5))
    }

    class func loadTopFilterName() -> String? {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let filterName = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.topFilterName) as? String else {
            return nil
        }

        return filterName
    }

    class func loadPlayingStatus() -> Bool {
        guard let sharedDefaults = UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId), let playingStatus = sharedDefaults.object(forKey: SharedConstants.GroupUserDefaults.isPlaying) as? Bool else {
            return false
        }

        return playingStatus
    }

    class func urlForEpisodeUuid(uuid: String) -> URL? {
        guard let url = URL(string: "pktc://widget-episode/\(uuid)") else {
            return nil
        }

        return url
    }

    class func durationString(duration: TimeInterval) -> String {
        TimeFormatter.shared.multipleUnitFormattedShortTime(time: duration)
    }
}
