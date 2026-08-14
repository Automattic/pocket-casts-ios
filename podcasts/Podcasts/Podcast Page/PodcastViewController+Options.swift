import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

/// The options displayed by the overflow button of the episodes tab
extension PodcastViewController {
    func showEpisodeOptions() {
        guard let podcast else { return }

        let optionPicker = OptionsPicker(title: nil)

        if shouldDisplayPodcastFeedReloadButton() {
            let reloadPodcastFeedAction = OptionAction(label: L10n.podcastFeedReloadButton, icon: "stats_skipping") { [weak self] in
                self?.reloadPodcastFeed(source: .menu)
            }
            optionPicker.addAction(action: reloadPodcastFeedAction)
        }

        let multiSelectAction = OptionAction(label: L10n.selectEpisodes, icon: "option-multiselect") { [weak self] in
            self?.enableMultiSelect()
        }
        optionPicker.addAction(action: multiSelectAction)

        let currentSort = podcast.podcastSortOrder?.description ?? ""
        let sortAction = OptionAction(label: L10n.sortEpisodes, secondaryLabel: currentSort, icon: "podcastlist_sort") {}
        sortAction.submenu = { [weak self] in self?.makeSortOptionsPicker() }
        optionPicker.addAction(action: sortAction)

        let currentGroup = podcast.podcastGrouping().description
        let groupAction = OptionAction(label: L10n.groupEpisodes, secondaryLabel: currentGroup, icon: "option-group") {}
        groupAction.submenu = { [weak self] in self?.makeGroupOptionsPicker() }
        optionPicker.addAction(action: groupAction)

        let downloadAllAction = OptionAction(label: L10n.downloadAll, icon: "filter_downloaded") {}
        downloadAllAction.submenu = { [weak self] in self?.makeDownloadAllPicker() }
        optionPicker.addAction(action: downloadAllAction)

        let unarchivedQuery = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ? AND archived = 0"
        let unarchivedCount = DataManager.sharedManager.count(query: unarchivedQuery, values: [podcast.id])
        if unarchivedCount > 0 {
            let archiveAllAction = OptionAction(label: L10n.podcastArchiveAll, icon: "podcast-archiveall") {}
            archiveAllAction.submenu = { [weak self] in self?.makeArchiveAllPicker(episodeCount: unarchivedCount, playedOnly: false) }
            optionPicker.addAction(action: archiveAllAction)
        } else if !(podcast.autoArchiveEpisodeLimit > 0 && podcast.overrideGlobalArchive) {
            // we only show unarchive all for podcasts that haven't set an episode limit
            let unarchiveAllAction = OptionAction(label: L10n.podcastUnarchiveAll, icon: "list_unarchive") { [weak self] in
                self?.unarchiveAll()
            }
            optionPicker.addAction(action: unarchiveAllAction)
        }

        let playedNotArchivedQuery = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ? AND archived = 0 AND playingStatus = \(PlayingStatus.completed.rawValue)"
        let playedNotArchivedCount = DataManager.sharedManager.count(query: playedNotArchivedQuery, values: [podcast.id])
        if playedNotArchivedCount > 0 {
            let archiveAllPlayedAction = OptionAction(label: L10n.podcastArchiveAllPlayed, icon: "podcast-archiveall") {}
            archiveAllPlayedAction.submenu = { [weak self] in self?.makeArchiveAllPicker(episodeCount: playedNotArchivedCount, playedOnly: true) }
            optionPicker.addAction(action: archiveAllPlayedAction)
        }

        optionPicker.present(from: self)
        Analytics.track(.podcastScreenOptionsTapped)
    }

    private func makeDownloadAllPicker() -> OptionsPicker? {
        let downloadableCount = downloadableEpisodeCount()
        let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
        let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
        if actualDownloadCount == 0 { return nil }
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

            let queueAction = OptionAction(label: L10n.queueForLater, icon: nil) { [weak self] in
                self?.queueAll()
            }
            queueAction.outline = true

            if !Settings.mobileDataAllowed() {
                warningMessage = L10n.downloadDataWarningWithSettingsLink("pktc://settings/storage-and-data") + "\n" + warningMessage
            }
            confirmPicker.addAttributedDescriptiveActions(title: L10n.notOnWifi, message: warningMessage, icon: "option-alert", actions: [downloadAction, queueAction])
        }

        return confirmPicker
    }

    private func makeArchiveAllPicker(episodeCount: Int, playedOnly: Bool) -> OptionsPicker? {
        let archiveAllConfirm = OptionsPicker(title: nil)
        let archiveAllAction = OptionAction(label: episodeCount == 1 ? L10n.podcastArchiveEpisodeCountSingular : L10n.podcastArchiveEpisodesCountPluralFormat(episodeCount.localized()), icon: nil) { [weak self] in
            self?.archiveAll(playedOnly: playedOnly)
        }
        archiveAllAction.destructive = true
        let title = playedOnly ? L10n.podcastArchiveAllPlayed : L10n.podcastArchiveAll
        archiveAllConfirm.addDescriptiveActions(title: title, message: L10n.podcastArchivePromptMsg, icon: "options-archiveall", actions: [archiveAllAction])

        return archiveAllConfirm
    }

    private func makeSortOptionsPicker() -> OptionsPicker? {
        guard let podcast else { return nil }

        let optionPicker = OptionsPicker(title: L10n.podcastSortOrderTitle)

        let sortOrder = podcast.podcastSortOrder

        PodcastEpisodeSortOrder.allCases.forEach { order in
            let newestToOldestAction = OptionAction(label: order.description, selected: sortOrder == order) { [weak self] in
                self?.setSortSetting(order)
                Analytics.track(.podcastsScreenSortOrderChanged, properties: ["sort_by": order])
            }

            optionPicker.addAction(action: newestToOldestAction)
        }

        return optionPicker
    }

    private func makeGroupOptionsPicker() -> OptionsPicker? {
        guard let podcast else { return nil }

        let optionPicker = OptionsPicker(title: L10n.podcastGroupOptionsTitle)

        let episodeGrouping = podcast.podcastGrouping()

        let groupings: [(label: String, grouping: PodcastGrouping)] = [
            (L10n.none, .none),
            (L10n.statusDownloaded, .downloaded),
            (L10n.statusUnplayed, .unplayed),
            (L10n.season, .season),
            (L10n.statusStarred, .starred)
        ]

        groupings.forEach { label, grouping in
            let action = OptionAction(label: label, selected: episodeGrouping == grouping) { [weak self] in
                self?.setGroupingSetting(grouping)
                Analytics.track(.podcastsScreenEpisodeGroupingChanged, properties: ["value": grouping])
            }
            optionPicker.addAction(action: action)
        }

        return optionPicker
    }

    private func setSortSetting(_ setting: PodcastEpisodeSortOrder) {
        guard let podcast else { return }

        podcast.episodeSortOrder = setting.old.rawValue
        DataManager.sharedManager.save(podcast: podcast)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }

    private func setGroupingSetting(_ setting: PodcastGrouping) {
        guard let podcast else { return }

        podcast.episodeGrouping = setting.rawValue
        DataManager.sharedManager.save(podcast: podcast)

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastUpdated, object: podcast.uuid)
    }
}
