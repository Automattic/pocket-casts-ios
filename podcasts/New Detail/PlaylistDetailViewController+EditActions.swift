import UIKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension PlaylistDetailViewController {
    @objc func moreTapped() {
        Analytics.track(.filterOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let chromecastAction = OptionAction(label: "Chromecast", icon: "nav_cast_off") {
//            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "filter_options"])
            self.castButtonTapped()
        }
        optionsPicker.addAction(action: chromecastAction)

        let MultiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
        optionsPicker.addAction(action: MultiSelectAction)

        let currentSort = PlaylistSort(rawValue: viewModel.playlist.sortType)?.description ?? ""
        let sortAction = OptionAction(label: L10n.sortBy, secondaryLabel: currentSort, icon: "podcastlist_sort") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "sort_by"])
            self.showSortByPicker()
        }
        let editAction = OptionAction(label: L10n.filterOptions, icon: "profile-settings") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "filter_options"])
            self.filterOptionsTapped()
        }

        let downloadAllAction = OptionAction(label: L10n.downloadAll, icon: "filter_downloaded") { [weak self] in
            guard let self = self else { return }
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "download_all"])

            let downloadableCount = self.downloadableCount(listEpisodes: self.viewModel.episodes)
            let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
            let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
            if actualDownloadCount == 0 { return }
            let downloadText = L10n.downloadCountPrompt(actualDownloadCount)
            let downloadAction = OptionAction(label: downloadText, icon: nil) { [weak self] in
                self?.downloadAll()
            }

            let confirmPicker = OptionsPicker(title: nil)
            var warningMessage = downloadLimitExceeded ? L10n.bulkDownloadMax : ""

            if NetworkUtils.shared.isConnectedToUnexpensiveConnection() {
                confirmPicker.addDescriptiveActions(title: L10n.downloadAll, message: warningMessage, icon: "filter_downloaded", actions: [downloadAction])
            } else {
                downloadAction.destructive = true

                let queueAction = OptionAction(label: L10n.queueForLater, icon: nil) {
                    self.queueAll()
                }

                if !Settings.mobileDataAllowed() {
                    warningMessage = L10n.downloadDataWarningWithSettingsLink("pktc://settings/storage-and-data") + "\n" + warningMessage
                }

                confirmPicker.addAttributedDescriptiveActions(title: L10n.notOnWifi, message: warningMessage, icon: "option-alert", actions: [downloadAction, queueAction])
            }
            confirmPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
        }

        optionsPicker.addAction(action: sortAction)
        optionsPicker.addAction(action: downloadAllAction)
        optionsPicker.addAction(action: editAction)

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
    
    func showSortByPicker() {
        let optionsPicker = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        addSortAction(to: optionsPicker, sortOrder: .newestToOldest)
        addSortAction(to: optionsPicker, sortOrder: .oldestToNewest)
        addSortAction(to: optionsPicker, sortOrder: .shortestToLongest)
        addSortAction(to: optionsPicker, sortOrder: .longestToShortest)

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }
    
    @objc func filterOptionsTapped() {
        let filterEditController = FilterEditOptionsViewController()
        filterEditController.filterToEdit = viewModel.playlist
        navigationController?.pushViewController(filterEditController, animated: true)
    }

    private func addSortAction(to optionPicker: OptionsPicker, sortOrder: PlaylistSort) {
        let action = OptionAction(label: sortOrder.description, selected: viewModel.playlist.sortType == sortOrder.rawValue) {
            Analytics.track(.filterSortByChanged, properties: ["sort_order": sortOrder])
            let playlist = self.viewModel.playlist!
            playlist.sortType = sortOrder.rawValue
            self.viewModel.update(playlist: playlist)
            self.savePlaylist()
        }
        optionPicker.addAction(action: action)
    }

    func savePlaylist() {
        var playlist = self.viewModel.playlist!
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        viewModel.update(playlist: playlist)
        DataManager.sharedManager.save(filter: viewModel.playlist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged, object: viewModel.playlist)
    }

    func downloadableCount(listEpisodes: [ListEpisode]) -> Int {
        if listEpisodes.count == 0 { return 0 }
        var count = 0

        for listEpisode in listEpisodes {
            if !listEpisode.episode.downloaded(pathFinder: DownloadManager.shared), !listEpisode.episode.downloading(), !listEpisode.episode.queued() {
                count += 1
            }
        }
        return count
    }

    func downloadAll() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.viewModel.episodes.count == 0 { return }

            self.downloadItems(allEpisodes: self.viewModel.episodes)
        }
    }
    
    func queueAll() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.viewModel.episodes.count == 0 { return }
            self.queueItems(allEpisodes: self.viewModel.episodes)
        }
    }

    func queueItems(allEpisodes: [ListEpisode]) {
        var queuedEpisodes = 0
        for listEpisode in allEpisodes {
            if listEpisode.episode.downloading() || listEpisode.episode.downloaded(pathFinder: DownloadManager.shared) || listEpisode.episode.queued() {
                continue
            }

            DownloadManager.shared.queueForLaterDownload(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)

            queuedEpisodes += 1
            if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                return
            }
        }
    }

    func downloadItems(allEpisodes: [ListEpisode]) {
        var queuedEpisodes = 0
        for listEpisode in allEpisodes {
            if listEpisode.episode.downloading() || listEpisode.episode.downloaded(pathFinder: DownloadManager.shared) || listEpisode.episode.queued() {
                continue
            }

            DownloadManager.shared.addToQueue(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
            queuedEpisodes += 1
            if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                return
            }
        }
    }
}
