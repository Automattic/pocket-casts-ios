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
                podcast.cachedUnreadCount == otherPodcast.cachedUnreadCount &&
                badgeType == rhs.badgeType &&
                podcast.startFrom == otherPodcast.startFrom &&
                podcast.autoDownloadSetting == otherPodcast.autoDownloadSetting &&
                podcast.overrideGlobalArchive == otherPodcast.overrideGlobalArchive &&
                podcast.autoArchiveInactiveAfter == otherPodcast.autoArchiveInactiveAfter &&
                podcast.autoArchivePlayedAfter == otherPodcast.autoArchivePlayedAfter &&
                podcast.subscribed == otherPodcast.subscribed &&
                podcast.episodeGrouping == otherPodcast.episodeGrouping
        }
        else if let otherFolder = rhs.folder, let folder = folder {
            return differenceIdentifier == rhs.differenceIdentifier &&
                folder.cachedUnreadCount == otherFolder.cachedUnreadCount &&
                badgeType == rhs.badgeType &&
                folder.name == otherFolder.name &&
                folder.color == otherFolder.color &&
                folder.syncModified == otherFolder.syncModified &&
                theme.rawValue == rhs.theme.rawValue // since folders use different colours in different themes, we need to compare that as well
        }
        
        return false
    }
}
