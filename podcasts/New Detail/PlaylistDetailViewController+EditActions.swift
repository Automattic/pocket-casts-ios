import UIKit
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

extension PlaylistDetailViewController {
    private enum ActionType {
        case downloadAll
        case queueAll
    }

    @objc func moreTapped() {
        Analytics.track(.filterOptionsButtonTapped)

        let optionsPicker = OptionsPicker(title: nil)

        let chromecastAction = chromecastAction()
        optionsPicker.addAction(action: chromecastAction)

        let multiSelectAction = multiSelectAction()
        optionsPicker.addAction(action: multiSelectAction)

        let sortAction = sortAction()
        optionsPicker.addAction(action: sortAction)

        if viewModel.isManualPlaylist {
            let reorderEpisodesAction = reorderEpisodesAction()
            optionsPicker.addAction(action: reorderEpisodesAction)
        }

        let downloadAllAction = downloadAllOption()
        optionsPicker.addAction(action: downloadAllAction)

        if viewModel.isManualPlaylist {
            let archiveAction = archiveAction()
            optionsPicker.addAction(action: archiveAction)
        }

        let editAction = editAction()
        optionsPicker.addAction(action: editAction)

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
    }

    // MARK: - Multiselect

    private func multiSelectAction() -> OptionAction {
        OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "select_episodes"])
            self?.isMultiSelectEnabled = true
        }
    }

    // MARK: - Chromecast

    private func chromecastAction() -> OptionAction {
        OptionAction(label: "Chromecast", icon: "nav_cast_off") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "chromecast"])
            self.castButtonTapped()
        }
    }

    // MARK: - Sort

    private func sortAction() -> OptionAction {
        let currentSort = PlaylistSort(rawValue: viewModel.playlist.sortType)?.description ?? ""
        return OptionAction(label: L10n.sortBy, secondaryLabel: currentSort, icon: "podcastlist_sort") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "sort_by"])
            self.showSortByPicker()
        }
    }

    private func showSortByPicker() {
        let optionsPicker = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        addSortAction(to: optionsPicker, sortOrder: .newestToOldest)
        addSortAction(to: optionsPicker, sortOrder: .oldestToNewest)
        addSortAction(to: optionsPicker, sortOrder: .shortestToLongest)
        addSortAction(to: optionsPicker, sortOrder: .longestToShortest)

        if viewModel.isManualPlaylist {
            addSortAction(to: optionsPicker, sortOrder: .dragAndDrop)
        }

        optionsPicker.show(statusBarStyle: AppTheme.defaultStatusBarStyle())
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

    private func savePlaylist() {
        let playlist = self.viewModel.playlist!
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        viewModel.update(playlist: playlist)
        DataManager.sharedManager.save(playlist: viewModel.playlist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: viewModel.playlist)
    }

    // MARK: - Edit Episodes order

    private func reorderEpisodesAction() -> OptionAction {
        OptionAction(label: L10n.playlistManualEpisodesOrderOption, icon: "filter_manual_episode_order") { [weak self] in
            //TODO: Add analytics
            guard let self = self else { return }
            self.showCustomOrderList()
        }
    }

    private func showCustomOrderList() {
        let customOrderViewController = PlaylistDetailCustomOrderViewController(viewModel: viewModel)
        navigationController?.pushViewController(customOrderViewController, animated: true)
    }

    // MARK: - Download

    private func downloadAllOption() -> OptionAction {
        OptionAction(label: L10n.downloadAll, icon: "filter_downloaded") { [weak self] in
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
    }

    private func downloadableCount(listEpisodes: [ListEpisode]) -> Int {
        if listEpisodes.count == 0 { return 0 }
        var count = 0

        for listEpisode in listEpisodes {
            if !listEpisode.episode.downloaded(pathFinder: DownloadManager.shared), !listEpisode.episode.downloading(), !listEpisode.episode.queued() {
                count += 1
            }
        }
        return count
    }

    private func downloadAll() {
        start(action: .downloadAll, forAllEpisodes: viewModel.episodes)
    }

    private func queueAll() {
        start(action: .queueAll, forAllEpisodes: viewModel.episodes)
    }

    private func start(action: ActionType, forAllEpisodes episodes: [ListEpisode]) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.viewModel.episodes.isEmpty { return }

            var queuedEpisodes = 0
            for listEpisode in episodes {
                if listEpisode.episode.downloading() || listEpisode.episode.downloaded(pathFinder: DownloadManager.shared) || listEpisode.episode.queued() {
                    continue
                }

                switch action {
                case .downloadAll:
                    DownloadManager.shared.addToQueue(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
                case .queueAll:
                    DownloadManager.shared.queueForLaterDownload(episodeUuid: listEpisode.episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
                }

                queuedEpisodes += 1
                if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                    return
                }
            }
        }
    }

    // MARK: - Archive

    private func archiveAction() -> OptionAction {
        let unarchivedCount = viewModel.unarchivedEpisodesCount()

        if unarchivedCount > 0 {
            return OptionAction(label: L10n.podcastArchiveAll, icon: "podcast-archiveall") { [weak self] in
                //TODO: Add Analytics
                self?.archiveAllPlaylistEpisodes()
            }
        }
        return OptionAction(label: L10n.podcastUnarchiveAll, icon: "list_unarchive") { [weak self] in
            //TODO: Add Analytics
            self?.unarchiveAllPlaylistEpisodes()
        }
    }

    private func archiveAllPlaylistEpisodes() {
        //PCIOS-118
    }

    private func unarchiveAllPlaylistEpisodes() {
        //PCIOS-118
    }

    // MARK: - Edit

    private func editAction() -> OptionAction {
        OptionAction(label: L10n.playlistOptions, icon: "profile-settings") {
            Analytics.track(.filterOptionsModalOptionTapped, properties: ["option": "filter_options"])
            self.playlistOptionsTapped()
        }
    }

    private func playlistOptionsTapped() {
        let filterEditController = FilterEditOptionsViewController()
        filterEditController.filterToEdit = viewModel.playlist
        navigationController?.pushViewController(filterEditController, animated: true)
    }
}
