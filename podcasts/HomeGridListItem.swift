import DifferenceKit
import Foundation
import PocketCastsDataModel

class HomeGridListItem: ListItem {
    let gridItem: HomeGridItem

    var podcast: Podcast? {
        gridItem.podcast
    }

    var folder: Folder? {
        gridItem.folder
    }

    let theme: Theme.ThemeType
    let badgeType: BadgeType
    var frozenBadgeCount = -1 // used for comparisons only

    init(gridItem: HomeGridItem, badgeType: BadgeType, theme: Theme.ThemeType) {
        self.gridItem = gridItem
        self.badgeType = badgeType
        self.theme = theme

        super.init()
    }

    override var differenceIdentifier: String {
        podcast?.uuid ?? folder?.uuid ?? ""
    }

    static func == (lhs: HomeGridListItem, rhs: HomeGridListItem) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? HomeGridListItem else { return false }

        if let otherPodcast = rhs.podcast, let podcast = podcast {
            return differenceIdentifier == rhs.differenceIdentifier &&
                frozenBadgeCount == rhs.frozenBadgeCount &&
                badgeType == rhs.badgeType &&
                podcast.startFrom == otherPodcast.startFrom &&
                podcast.autoDownloadSetting == otherPodcast.autoDownloadSetting &&
                podcast.overrideGlobalArchive == otherPodcast.overrideGlobalArchive &&
                podcast.autoArchiveInactiveAfter == otherPodcast.autoArchiveInactiveAfter &&
                podcast.autoArchivePlayedAfter == otherPodcast.autoArchivePlayedAfter &&
                podcast.subscribed == otherPodcast.subscribed &&
                podcast.episodeGrouping == otherPodcast.episodeGrouping &&
                podcast.playbackSpeed == otherPodcast.playbackSpeed &&
                podcast.boostVolume == otherPodcast.boostVolume &&
                podcast.trimSilenceAmount == otherPodcast.trimSilenceAmount &&
                podcast.settings == otherPodcast.settings
        } else if let otherFolder = rhs.folder, let folder = folder {
            return differenceIdentifier == rhs.differenceIdentifier &&
                frozenBadgeCount == rhs.frozenBadgeCount &&
                badgeType == rhs.badgeType &&
                folder.name == otherFolder.name &&
                folder.color == otherFolder.color &&
                folder.syncModified == otherFolder.syncModified &&
                folder.sortType == otherFolder.sortType &&
                folder.sortOrder == otherFolder.sortOrder &&
                theme.rawValue == rhs.theme.rawValue // since folders use different colours in different themes, we need to compare that as well
        }

        return false
    }
}
