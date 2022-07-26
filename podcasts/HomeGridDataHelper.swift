import Foundation
import PocketCastsDataModel
import PocketCastsServer

class HomeGridDataHelper {
    class func gridListItemsForSearchTerm(_ searchTerm: String) -> [HomeGridItem] {
        let allPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        
        var filteredItems = [HomeGridItem]()
        for podcast in allPodcasts {
            guard let title = podcast.title else { continue }
            
            if title.localizedCaseInsensitiveContains(searchTerm) {
                filteredItems.append(HomeGridItem(podcast: podcast))
            }
            else if let author = podcast.author, author.localizedCaseInsensitiveContains(searchTerm) {
                filteredItems.append(HomeGridItem(podcast: podcast))
            }
        }
        
        if SubscriptionHelper.hasActiveSubscription() {
            let allFolders = DataManager.sharedManager.allFolders()
            for folder in allFolders {
                if folder.name.localizedCaseInsensitiveContains(searchTerm) {
                    filteredItems.append(HomeGridItem(folder: folder))
                }
            }
        }
        
        filteredItems.sort { item1, item2 in
            titleSort(item1: item1, item2: item2)
        }
        
        return filteredItems
    }
    
    #if !os(watchOS)
        class func gridListItems(orderedBy: LibrarySort, badgeType: BadgeType) -> [HomeGridListItem] {
            let allPodcasts = orderedBy == .episodeDateNewestToOldest ? PodcastManager.shared.allPodcastsSorted(in: .episodeDateNewestToOldest) : DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
            let gridItems: [HomeGridListItem] = gridItems(orderedBy: orderedBy, sortedPodcasts: allPodcasts).map { HomeGridListItem(gridItem: $0, badgeType: badgeType, theme: Theme.sharedTheme.activeTheme) }

            // load the required badge information if the supplied badge type needs it
            if badgeType == .allUnplayed {
                let podcastCounts = DataManager.sharedManager.podcastUnfinishedCounts()
                for gridItem in gridItems {
                    if let podcast = gridItem.podcast {
                        podcast.cachedUnreadCount = Int(podcastCounts[podcast.uuid] ?? 0)
                        gridItem.frozenBadgeCount = podcast.cachedUnreadCount
                    }
                    else if let folder = gridItem.folder {
                        // for a folder, it's badge count is a sum of all the ones for all the podcasts inside it
                        let allPodcastsInFolder = allPodcasts.filter { $0.folderUuid == folder.uuid }
                        folder.cachedUnreadCount = 0
                        for podcast in allPodcastsInFolder {
                            folder.cachedUnreadCount += Int(podcastCounts[podcast.uuid] ?? 0)
                        }
                        gridItem.frozenBadgeCount = folder.cachedUnreadCount
                    }
                }
            }
            else if badgeType == .latestEpisode {
                for gridItem in gridItems {
                    if let podcast = gridItem.podcast {
                        if let latestEpisode = DataManager.sharedManager.findLatestEpisode(podcast: podcast) {
                            podcast.cachedUnreadCount = latestEpisode.unplayed() && !latestEpisode.archived ? 1 : 0
                        }
                        else {
                            podcast.cachedUnreadCount = 0
                        }
                        gridItem.frozenBadgeCount = podcast.cachedUnreadCount
                    }
                    else if let folder = gridItem.folder {
                        // for a folder, we show a latest episode badge if any of the podcasts inside it should have one
                        let allPodcastsInFolder = allPodcasts.filter { $0.folderUuid == folder.uuid }
                        var shouldShowUnplayedBadge = false
                        for podcast in allPodcastsInFolder {
                            if let latestEpisode = DataManager.sharedManager.findLatestEpisode(podcast: podcast), latestEpisode.unplayed(), !latestEpisode.archived {
                                shouldShowUnplayedBadge = true
                                break
                            }
                        }
                        folder.cachedUnreadCount = shouldShowUnplayedBadge ? 1 : 0
                        gridItem.frozenBadgeCount = folder.cachedUnreadCount
                    }
                }
            }
        
            return gridItems
        }
    #endif
    
    class func gridItems(orderedBy: LibrarySort) -> [HomeGridItem] {
        let allPodcasts = orderedBy == .episodeDateNewestToOldest ? PodcastManager.shared.allPodcastsSorted(in: .episodeDateNewestToOldest) : DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        
        return gridItems(orderedBy: orderedBy, sortedPodcasts: allPodcasts)
    }
    
    private class func gridItems(orderedBy: LibrarySort, sortedPodcasts: [Podcast]) -> [HomeGridItem] {
        // When a user doesn't have Pocket Casts Plus, all their podcasts will be loaded into the main grid, regardless of if they are in a folder or not
        var gridItems: [HomeGridItem] = []
        if SubscriptionHelper.hasActiveSubscription() {
            let allFolders = DataManager.sharedManager.allFolders()
            
            gridItems += sortedPodcasts.compactMap { podcast in
                allFolders.contains { $0.uuid == podcast.folderUuid } ? nil : HomeGridItem(podcast: podcast)
            }
            gridItems += allFolders.map { HomeGridItem(folder: $0) }
        }
        else {
            gridItems += sortedPodcasts.map { HomeGridItem(podcast: $0) }
        }
        
        // sort the grid items based on the supplied sort order
        gridItems.sort { item1, item2 in
            switch orderedBy {
            case .dateAddedNewestToOldest:
                return dateAddedSort(item1: item1, item2: item2)
            case .titleAtoZ:
                return titleSort(item1: item1, item2: item2)
            case .episodeDateNewestToOldest:
                return latestEpisodeSort(item1: item1, item2: item2, sortedPodcasts: sortedPodcasts)
            case .custom:
                return customSort(item1: item1, item2: item2)
            }
        }
        
        return gridItems
    }
    
    private class func titleSort(item1: HomeGridItem, item2: HomeGridItem) -> Bool {
        guard let title1 = item1.podcast?.title ?? item1.folder?.name, let title2 = item2.podcast?.title ?? item2.folder?.name else { return false }
        
        var convertedTitle1 = title1
        var convertedTitle2 = title2
        if let range = convertedTitle1.range(of: "^the ", options: [.regularExpression, .caseInsensitive]) {
            convertedTitle1 = String(convertedTitle1[range.upperBound...])
        }
        if let range = convertedTitle2.range(of: "^the ", options: [.regularExpression, .caseInsensitive]) {
            convertedTitle2 = String(convertedTitle2[range.upperBound...])
        }

        return convertedTitle1.localizedLowercase.compare(convertedTitle2.localizedLowercase) == .orderedAscending
    }
    
    private class func customSort(item1: HomeGridItem, item2: HomeGridItem) -> Bool {
        let order1 = item1.podcast?.sortOrder ?? item1.folder?.sortOrder ?? 0
        let order2 = item2.podcast?.sortOrder ?? item2.folder?.sortOrder ?? 0
        
        return order2 > order1
    }
    
    private class func dateAddedSort(item1: HomeGridItem, item2: HomeGridItem) -> Bool {
        guard let date1 = item1.podcast?.addedDate ?? item1.folder?.addedDate, let date2 = item2.podcast?.addedDate ?? item2.folder?.addedDate else { return false }
        
        return date1.compare(date2) == .orderedAscending
    }
    
    // this function relies on sortedPodcasts already being in latest episode sort order, and then uses that to also figure out where a folder should be based on it's top sorted podcast
    private class func latestEpisodeSort(item1: HomeGridItem, item2: HomeGridItem, sortedPodcasts: [Podcast]) -> Bool {
        let index1 = indexOfItemInSortedList(item: item1, sortedPodcasts: sortedPodcasts)
        let index2 = indexOfItemInSortedList(item: item2, sortedPodcasts: sortedPodcasts)
        
        return index1 < index2
    }
    
    private class func indexOfItemInSortedList(item: HomeGridItem, sortedPodcasts: [Podcast]) -> Int {
        if let podcast = item.podcast {
            return sortedPodcasts.firstIndex(of: podcast) ?? 0
        }
        
        guard let folderUuid = item.folder?.uuid else { return 0 }
        
        return sortedPodcasts.firstIndex { $0.folderUuid == folderUuid } ?? 0
    }
}
