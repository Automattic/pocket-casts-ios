import CarPlay
import Foundation
import PocketCastsDataModel

extension CarPlaySceneDelegate {
    func createPodcastsTab() -> CPTemplate {
        var podcastItems = [CPListTemplateItem]()

        let gridItems = HomeGridDataHelper.gridItems(orderedBy: Settings.homeFolderSortOrder())

        for item in gridItems {
            if let podcast = item.podcast {
                let item = convertPodcastToListItem(podcast)
                podcastItems.append(item)
            } else if let folder = item.folder {
                let podcastCount = DataManager.sharedManager.countOfPodcastsInFolder(folder: folder)
                let item = CPListItem(text: folder.name, detailText: L10n.podcastCount(podcastCount), image: CarPlayImageHelper.imageForFolder(folder))

                item.accessoryType = .disclosureIndicator
                item.handler = { [weak self] _, completion in
                    self?.folderTapped(folder, closeListOnTap: false)
                    completion()
                }
                podcastItems.append(item)
            }
        }

        // the podcast tab is always what CarPlay opens first, however it doesn't show the Now Playing tab unless something is actively playing
        // so with that in mind if the user has something in Up Next and Pocket Casts is paused, help them find their now playing stuff by adding that as a section here
        let upNextEpisodes = PlaybackManager.shared.allEpisodesInQueue(includeNowPlaying: true)
        if upNextEpisodes.count > 0 {
            let truncatedList = Array(upNextEpisodes.prefix(8))
            let imageRowItem = createUpNextImageItem(episodes: truncatedList)

            podcastItems.insert(imageRowItem, at: 0)
        }

        let podcastsSection = CPListSection(items: podcastItems)
        let template = CPListTemplate(title: L10n.podcastsPlural, sections: [podcastsSection])
        template.tabTitle = L10n.podcastsPlural
        template.tabImage = UIImage(named: "car_tab_podcasts")

        return template
    }

    func createFiltersTab() -> CPTemplate {
        var filterItems = [CPListItem]()
        for filter in DataManager.sharedManager.allFilters(includeDeleted: false) {
            let item = CPListItem(text: filter.playlistName, detailText: nil, image: UIImage(named: filter.iconImageNameCarPlay()))
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                self?.filterTapped(filter)
                completion()
            }

            filterItems.append(item)
        }

        let filtersSection = CPListSection(items: filterItems)
        let template = CPListTemplate(title: L10n.filters, sections: [filtersSection])
        template.tabTitle = L10n.filters
        template.tabImage = UIImage(named: "car_tab_filters")

        return template
    }

    func createDownloadsTab() -> CPTemplate {
        let downloadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "episodeStatus == \(DownloadStatus.downloaded.rawValue) ORDER BY lastDownloadAttemptDate DESC LIMIT \(Constants.Limits.maxCarplayItems)", arguments: nil)
        let items = convertToListItems(episodes: downloadedEpisodes, showArtwork: true, closeListOnTap: false)

        let episodeSection = CPListSection(items: items)
        let template = CPListTemplate(title: L10n.downloads, sections: [episodeSection])
        template.tabTitle = L10n.downloads
        template.tabImage = UIImage(named: "car_tab_downloads")

        return template
    }

    func createMoreTab() -> CPTemplate {
        let listeningHistoryItem = CPListItem(text: L10n.listeningHistory, detailText: nil, image: UIImage(named: "car_more_listening_history"))
        listeningHistoryItem.accessoryType = .disclosureIndicator
        listeningHistoryItem.handler = { [weak self] _, completion in
            self?.listeningHistoryTapped()
            completion()
        }

        let filesItem = CPListItem(text: L10n.files, detailText: nil, image: UIImage(named: "car_more_files"))
        filesItem.accessoryType = .disclosureIndicator
        filesItem.handler = { [weak self] _, completion in
            self?.filesTapped(closeListOnTap: false)
            completion()
        }

        let mainSection = CPListSection(items: [listeningHistoryItem, filesItem])
        let template = CPListTemplate(title: L10n.carplayMore, sections: [mainSection])
        template.tabTitle = L10n.carplayMore
        template.tabImage = UIImage(named: "car_tab_more")

        return template
    }
}
