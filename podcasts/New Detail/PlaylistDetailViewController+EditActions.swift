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
        track(.filterOptionsTapped)

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
            self?.track(.filterSelectEpisodesTapped)
            self?.isMultiSelectEnabled = true
        }
    }

    // MARK: - Chromecast

    private func chromecastAction() -> OptionAction {
        OptionAction(label: "Chromecast", icon: "nav_cast_off") { [weak self] in
            self?.track(.filterChromeCastTapped)
            self?.castButtonTapped()
        }
    }

    // MARK: - Sort

    private func sortAction() -> OptionAction {
        let currentSort = PlaylistSort(rawValue: viewModel.playlist.sortType)?.description ?? ""
        return OptionAction(label: L10n.sortBy, secondaryLabel: currentSort, icon: "podcastlist_sort") { [weak self] in
            self?.track(.filterSortByTapped)
            self?.showSortByPicker()
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
        let action = OptionAction(label: sortOrder.description, selected: viewModel.playlist.sortType == sortOrder.rawValue) { [weak self] in
            guard let self else { return }
            self.track(.filterSortByChanged, properties: ["sort_order": sortOrder])
            let playlist = self.viewModel.playlist
            playlist.sortType = sortOrder.rawValue
            self.viewModel.update(playlist: playlist)
            self.savePlaylist()
        }
        optionPicker.addAction(action: action)
    }

    private func savePlaylist() {
        let playlist = self.viewModel.playlist
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        viewModel.update(playlist: playlist)
        DataManager.sharedManager.save(playlist: viewModel.playlist)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: viewModel.playlist)
    }

    // MARK: - Edit Episodes order

    private func reorderEpisodesAction() -> OptionAction {
        OptionAction(label: L10n.playlistManualEpisodesOrderOption, icon: "filter_manual_episode_order") { [weak self] in
            guard let self else { return }
            self.track(.filterRearrangeEpisodesTapped)
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
            guard let self else { return }
            self.track(.filterDownloadAllTapped)

            let downloadableCount = self.downloadableCount(listEpisodes: self.viewModel.episodes)
            let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
            let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
            if actualDownloadCount == 0 { return }
            let downloadText = L10n.downloadCountPrompt(actualDownloadCount)

            let onWifi = NetworkUtils.shared.isConnectedToUnexpensiveConnection()

            if FeatureFlag.liquidGlass.enabled {
                let title = onWifi ? L10n.alertDownloadAll : L10n.notOnWifi
                let downloadable = self.downloadableEpisodes(from: self.viewModel.episodes)
                let totalSize = self.estimatedDownloadSize(from: downloadable, limit: actualDownloadCount)
                var messageParts = [String]()
                if totalSize > 0 {
                    let sizeString = SizeFormatter.shared.noDecimalFormat(bytes: totalSize)
                    messageParts.append(L10n.downloadEstimatedSize(sizeString))
                }
                if downloadLimitExceeded {
                    messageParts.append(L10n.bulkDownloadMax)
                }
                if !onWifi, !Settings.mobileDataAllowed() {
                    messageParts.append(L10n.downloadDataWarningAlert)
                }
                let message = messageParts.joined(separator: "\n")

                let alert = UIAlertController(title: title, message: message.isEmpty ? nil : message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: downloadText, style: onWifi ? .default : .destructive) { _ in
                    self.downloadAll()
                })
                if !onWifi {
                    alert.addAction(UIAlertAction(title: L10n.queueForLater, style: .default) { _ in
                        self.queueAll()
                    })
                    if !Settings.mobileDataAllowed() {
                        alert.addAction(UIAlertAction(title: L10n.settings, style: .default) { _ in
                            if let url = URL(string: "pktc://settings/storage-and-data") {
                                UIApplication.shared.open(url)
                            }
                        })
                    }
                }
                alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
                self.present(alert, animated: true)
            } else {
                let downloadAction = OptionAction(label: downloadText, icon: nil) { [weak self] in
                    self?.downloadAll()
                }

                let confirmPicker = OptionsPicker(title: nil)
                var warningMessage = downloadLimitExceeded ? L10n.bulkDownloadMax : ""

                if onWifi {
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
    }

    private func downloadableEpisodes(from listEpisodes: [ListEpisode]) -> [ListEpisode] {
        listEpisodes.filter {
            !$0.episode.downloaded(pathFinder: DownloadManager.shared) && !$0.episode.downloading() && !$0.episode.queued()
        }
    }

    private func downloadableCount(listEpisodes: [ListEpisode]) -> Int {
        downloadableEpisodes(from: listEpisodes).count
    }

    private func estimatedDownloadSize(from listEpisodes: [ListEpisode], limit: Int) -> Int64 {
        listEpisodes.prefix(limit).reduce(0) { $0 + $1.episode.sizeInBytes }
    }

    private func downloadAll() {
        start(action: .downloadAll, forAllEpisodes: viewModel.episodes)
    }

    private func queueAll() {
        start(action: .queueAll, forAllEpisodes: viewModel.episodes)
    }

    private func start(action: ActionType, forAllEpisodes episodes: [ListEpisode]) {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }

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
                self?.track(.filterArchiveAllTapped)
                self?.archiveAllPlaylistEpisodes()
            }
        }
        return OptionAction(label: L10n.podcastUnarchiveAll, icon: "list_unarchive") { [weak self] in
            self?.track(.filterUnarchiveAllTapped)
            self?.unarchiveAllPlaylistEpisodes()
        }
    }

    private func archiveAllPlaylistEpisodes() {
        let episodes = viewModel.episodes.map { $0.episode }
        EpisodeManager.bulkArchive(episodes: episodes, updateSyncFlag: true)
    }

    private func unarchiveAllPlaylistEpisodes() {
        Task { [weak self] in
            guard let self else { return }
            let newData = self.viewModel.episodesDataManager.playlistEpisodes(for: self.viewModel.playlist, shouldShowArchived: true)
            let episodes = newData.map { $0.episode }
            EpisodeManager.bulkUnarchive(episodes: episodes)
        }
    }

    // MARK: - Edit

    private func editAction() -> OptionAction {
        OptionAction(label: L10n.playlistOptions, icon: "profile-settings") { [weak self] in
            self?.track(.filterOptionsButtonTapped)
            self?.playlistOptionsTapped()
        }
    }

    private func playlistOptionsTapped() {
        let filterEditController = FilterEditOptionsViewController()
        filterEditController.filterToEdit = viewModel.playlist
        navigationController?.pushViewController(filterEditController, animated: true)
    }
}
