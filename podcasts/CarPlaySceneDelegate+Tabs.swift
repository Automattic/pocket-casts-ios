import CarPlay
import Foundation
import PocketCastsDataModel

// MARK: - Podcasts
extension CarPlaySceneDelegate {
    var podcastTabSections: [CPListSection] {
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
                    self?.folderTapped(folder)
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

        return [CPListSection(items: podcastItems)]
    }

    func createPodcastsTab() -> CPListTemplate {
        return CarPlayListData.template(title: L10n.podcastsPlural, emptyTitle: L10n.watchNoPodcasts, image: UIImage(named: "car_tab_podcasts")) { [weak self] in
            guard let self else { return nil }

            return self.podcastTabSections
        }
    }
}

// MARK: - Filters

extension CarPlaySceneDelegate {
    private var filterTabSections: [CPListSection] {
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

        return [CPListSection(items: filterItems)]
    }

    func createFiltersTab() -> CPListTemplate {
        return CarPlayListData.template(title: L10n.filters, emptyTitle: L10n.watchNoFilters, image: UIImage(named: "car_tab_filters")) { [weak self] in
            guard let self else { return nil }
            return self.filterTabSections
        }
    }
}

// MARK: - Downloads

extension CarPlaySceneDelegate {
    private var downloadTabSections: [CPListSection] {
        let downloadedEpisodes = DataManager.sharedManager.findEpisodesWhere(customWhere: "episodeStatus == \(DownloadStatus.downloaded.rawValue) ORDER BY lastDownloadAttemptDate DESC LIMIT \(Constants.Limits.maxCarplayItems)", arguments: nil)
        let items = convertToListItems(episodes: downloadedEpisodes, showArtwork: true)

        return [CPListSection(items: items)]
    }

    func createDownloadsTab() -> CPListTemplate {
        return CarPlayListData.template(title: L10n.downloads, emptyTitle: L10n.downloadsNoDownloadsTitle, image: UIImage(named: "car_tab_downloads")) { [weak self] in
            guard let self else { return nil }

            return self.downloadTabSections
        }
    }
}

// MARK: - More

extension CarPlaySceneDelegate {
    func createMoreTab() -> CPListTemplate {
        return CarPlayListData.staticTemplate(title: L10n.carplayMore, image: UIImage(named: "car_tab_more")) {
            let listeningHistoryItem = CPListItem(text: L10n.listeningHistory, detailText: nil, image: UIImage(named: "car_more_listening_history"))
            listeningHistoryItem.accessoryType = .disclosureIndicator
            listeningHistoryItem.handler = { [weak self] _, completion in
                self?.listeningHistoryTapped()
                completion()
            }

            let filesItem = CPListItem(text: L10n.files, detailText: nil, image: UIImage(named: "car_more_files"))
            filesItem.accessoryType = .disclosureIndicator
            filesItem.handler = { [weak self] _, completion in
                self?.filesTapped()
                completion()
            }

            return [CPListSection(items: [listeningHistoryItem, filesItem])]
        }
    }
}
