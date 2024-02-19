import DifferenceKit
import Foundation
import PocketCastsDataModel

class ListPodcast: ListItem {
    let podcast: Podcast
    let badgeType: BadgeType

    init(podcast: Podcast, badgeType: BadgeType) {
        self.podcast = podcast
        self.badgeType = badgeType

        super.init()
    }

    override var differenceIdentifier: String {
        podcast.uuid
    }

    static func == (lhs: ListPodcast, rhs: ListPodcast) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? ListPodcast else { return false }

        return differenceIdentifier == rhs.differenceIdentifier &&
            podcast.cachedUnreadCount == rhs.podcast.cachedUnreadCount &&
            badgeType == rhs.badgeType &&
            podcast.startFrom == rhs.podcast.startFrom &&
            podcast.autoDownloadSetting == rhs.podcast.autoDownloadSetting &&
            podcast.overrideGlobalArchive == rhs.podcast.overrideGlobalArchive &&
            podcast.autoArchiveInactiveAfter == rhs.podcast.autoArchiveInactiveAfter &&
            podcast.autoArchivePlayedAfter == rhs.podcast.autoArchivePlayedAfter &&
            podcast.subscribed == rhs.podcast.subscribed &&
            podcast.episodeGrouping == rhs.podcast.episodeGrouping &&
            podcast.settings == rhs.podcast.settings
    }
}
