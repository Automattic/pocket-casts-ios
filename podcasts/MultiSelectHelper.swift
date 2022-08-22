import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class MultiSelectHelper {
    // MARK: - Action Helpers
    
    class func performAction(_ action: MultiSelectAction, actionDelegate: MultiSelectActionDelegate) {
        switch action {
        case .star:
            starEpisodes(actionDelegate: actionDelegate, star: true)
        case .unstar:
            starEpisodes(actionDelegate: actionDelegate, star: false)
        case .archive:
            archiveEpisodes(actionDelegate: actionDelegate)
        case .unarchive:
            unarchiveEpisodes(actionDelegate: actionDelegate)
        case .playNext:
            playEpisodes(actionDelegate: actionDelegate, toTop: true)
        case .playLast:
            playEpisodes(actionDelegate: actionDelegate, toTop: false)
        case .markAsPlayed:
            markAsPlayedEpisodes(actionDelegate: actionDelegate)
        case .markAsUnplayed:
            markAsUnplayedEpisodes(actionDelegate: actionDelegate)
        case .download:
            downloadOrQueueEpisodes(actionDelegate: actionDelegate)
        case .removeDownload:
            removeDownload(actionDelegate: actionDelegate)
        case .moveToTop:
            moveToTop(actionDelegate: actionDelegate)
        case .moveToBottom:
            moveToBottom(actionDelegate: actionDelegate)
        case .removeFromUpNext:
            removeFromUpNext(actionDelegate: actionDelegate)
        case .delete:
            delete(actionDelegate: actionDelegate)
        }
    }
    
    private class func starEpisodes(actionDelegate: MultiSelectActionDelegate, star: Bool) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes().compactMap { $0 as? Episode }
        if star {
            let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectStarringEpisodesSingular : L10n.Localizable.multiSelectStarringEpisodesPluralFormat(selectedEpisodes.count.localized())
            actionDelegate.multiSelectActionBegan(status: status)
        }
        else {
            let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectUnstarringEpisodesSingular : L10n.Localizable.multiSelectUnstarringEpisodesPluralFormat(selectedEpisodes.count.localized())
            actionDelegate.multiSelectActionBegan(status: status)
        }
        DispatchQueue.global().async {
            EpisodeManager.bulkSetStarred(star, episodes: selectedEpisodes, updateSyncStatus: SyncManager.isUserLoggedIn())
            actionDelegate.multiSelectActionCompleted()
        }
    }

    private static func deleteFileMessage(_ count: Int) -> String {
        count == 1 ? L10n.Localizable.multiSelectDeleteFileMessageSingular : L10n.Localizable.multiSelectDeleteFileMessagePlural(count.localized())
    }
    
    private class func delete(actionDelegate: MultiSelectActionDelegate) {
        guard let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes() as? [UserEpisode] else { return }
        
        let downloadedEpisodes = selectedEpisodes.filter { $0.downloaded(pathFinder: DownloadManager.shared) }
        let uploadedEpisodes = selectedEpisodes.filter { $0.uploaded() }
        
        let confirmPicker: OptionsPicker
        if downloadedEpisodes.count == 0 {
            confirmPicker = OptionsPicker(title: nil)
            let deleteFromCloudAction = OptionAction(label: L10n.Localizable.deleteFromCloud, icon: nil) { () in
                DispatchQueue.global().async {
                    for episode in uploadedEpisodes {
                        UserEpisodeManager.deleteFromCloud(episode: episode)
                    }
                    
                    actionDelegate.multiSelectActionCompleted()
                }
            }
            
            let warningMessage = deleteFileMessage(uploadedEpisodes.count)
            confirmPicker.addDescriptiveActions(title: L10n.Localizable.deleteFromCloud, message: warningMessage, icon: "episode-delete", actions: [deleteFromCloudAction])
        }
        else if uploadedEpisodes.count == 0 {
            confirmPicker = OptionsPicker(title: nil)
            let deleteFromDeviceAction = OptionAction(label: L10n.Localizable.deleteFromDeviceOnly, icon: nil) { () in
                DispatchQueue.global().async {
                    for episode in downloadedEpisodes {
                        UserEpisodeManager.deleteFromDevice(userEpisode: episode)
                    }
                    
                    actionDelegate.multiSelectActionCompleted()
                }
            }
            
            let warningMessage = deleteFileMessage(downloadedEpisodes.count)
            confirmPicker.addDescriptiveActions(title: L10n.Localizable.deleteFromDevice, message: warningMessage, icon: "episode-delete", actions: [deleteFromDeviceAction])
        }
        else {
            confirmPicker = OptionsPicker(title: nil)
            let deleteEverwhereAction = OptionAction(label: L10n.Localizable.deleteEverywhere, icon: nil) { () in
                DispatchQueue.global().async {
                    for episode in selectedEpisodes {
                        UserEpisodeManager.deleteFromEverywhere(userEpisode: episode)
                    }
                
                    actionDelegate.multiSelectActionCompleted()
                }
            }

            let deleteFromDeviceAction = OptionAction(label: L10n.Localizable.deleteFromDeviceOnly, icon: nil) { () in
                DispatchQueue.global().async {
                    for episode in downloadedEpisodes {
                        UserEpisodeManager.deleteFromDevice(userEpisode: episode)
                    }
                    
                    actionDelegate.multiSelectActionCompleted()
                }
            }
            deleteFromDeviceAction.outline = true
            
            let warningMessage = deleteFileMessage(downloadedEpisodes.count)
            confirmPicker.addDescriptiveActions(title: L10n.Localizable.deleteFile, message: warningMessage, icon: "episode-delete", actions: [deleteFromDeviceAction, deleteEverwhereAction])
        }
        
        confirmPicker.show(statusBarStyle: actionDelegate.multiSelectPreferredStatusBarStyle())
    }
    
    private class func archiveEpisodes(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes().compactMap { $0 as? Episode }
        let selectedUserEpisodes = actionDelegate.multiSelectedBaseEpisodes().compactMap { $0 as? UserEpisode }
        let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectArchivingEpisodesSingular : L10n.Localizable.multiSelectArchivingEpisodesPluralFormat(selectedEpisodes.count.localized())
        actionDelegate.multiSelectActionBegan(status: status)
        DispatchQueue.global().async {
            EpisodeManager.bulkArchive(episodes: selectedEpisodes, removeFromPlayer: true, updateSyncFlag: SyncManager.isUserLoggedIn())
            EpisodeManager.bulkMarkAsPlayed(episodes: selectedUserEpisodes, updateSyncFlag: SyncManager.isUserLoggedIn())
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func unarchiveEpisodes(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes().compactMap { $0 as? Episode }
        let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectUnarchivingEpisodesSingular : L10n.Localizable.multiSelectUnarchivingEpisodesPluralFormat(selectedEpisodes.count.localized())
        actionDelegate.multiSelectActionBegan(status: status)
        DispatchQueue.global().async {
            EpisodeManager.bulkUnarchive(episodes: selectedEpisodes)
            
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func playEpisodes(actionDelegate: MultiSelectActionDelegate, toTop: Bool) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        var episodesToAdd = selectedEpisodes
        let statusTime = Date()
        var showDelayedCompletionMessage = false
        let bulkAddLimit = ServerSettings.autoAddToUpNextLimit()
        if selectedEpisodes.count > bulkAddLimit {
            episodesToAdd = Array(selectedEpisodes[0 ..< bulkAddLimit])
            showDelayedCompletionMessage = true
            let status = L10n.Localizable.multiSelectAddEpisodesMaxFormat(bulkAddLimit.localized())
            actionDelegate.multiSelectActionBegan(status: status)
        }
        else {
            let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectAddingEpisodesSingular : L10n.Localizable.multiSelectAddingEpisodesPluralFormat(selectedEpisodes.count.localized())
            actionDelegate.multiSelectActionBegan(status: status)
        }
        DispatchQueue.global().async {
            PlaybackManager.shared.bulkAdd(episodesToAdd, toTop: toTop)
            if showDelayedCompletionMessage {
                let timeSinceStatusDisplayed = 0 - statusTime.timeIntervalSinceNow
                if timeSinceStatusDisplayed < Constants.Animation.multiSelectStatusDelayTime {
                    let delay = Constants.Animation.multiSelectStatusDelayTime - timeSinceStatusDisplayed
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) { () in
                        actionDelegate.multiSelectActionCompleted()
                    }
                    return
                }
            }
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func markAsPlayedEpisodes(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectMarkEpisodesPlayedSingular : L10n.Localizable.multiSelectMarkEpisodesPlayedPluralFormat(selectedEpisodes.count.localized())
        actionDelegate.multiSelectActionBegan(status: status)
        
        DispatchQueue.global().async {
            EpisodeManager.bulkMarkAsPlayed(episodes: selectedEpisodes, updateSyncFlag: SyncManager.isUserLoggedIn())
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func markAsUnplayedEpisodes(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectMarkEpisodesUnplayedSingular : L10n.Localizable.multiSelectMarkEpisodesUnplayedPluralFormat(selectedEpisodes.count.localized())
        actionDelegate.multiSelectActionBegan(status: status)
        
        DispatchQueue.global().async {
            EpisodeManager.bulkMarkAsUnPlayed(selectedEpisodes)
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func downloadOrQueueEpisodes(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        
        let downloadableEpisodes = selectedEpisodes.filter { !$0.downloading() && !$0.queued() && !$0.downloaded(pathFinder: DownloadManager.shared) }
        
        let downloadableCount = downloadableEpisodes.count
        let downloadLimitExceeded = downloadableCount > Constants.Limits.maxBulkDownloads
        let actualDownloadCount = downloadLimitExceeded ? Constants.Limits.maxBulkDownloads : downloadableCount
        if actualDownloadCount == 0 {
            actionDelegate.multiSelectActionCompleted()
            return
        }
        
        let downloadText = L10n.downloadCountPrompt(selectedEpisodes.count).localizedUppercase
        let downloadAction = OptionAction(label: downloadText, icon: nil) { () in
            MultiSelectHelper.downloadEpisodes(downloadableEpisodes, actionDelegate: actionDelegate)
            actionDelegate.multiSelectActionCompleted()
        }
        
        let confirmPicker = OptionsPicker(title: nil)
        var warningMessage = downloadLimitExceeded ? L10n.bulkDownloadMax : ""
        
        if NetworkUtils.shared.isConnectedToWifi() {
            if downloadableCount < 5 {
                let status = L10n.Localizable.multiSelectDownloadingEpisodesFormat(selectedEpisodes.count.localized())
                actionDelegate.multiSelectActionBegan(status: status)
                MultiSelectHelper.downloadEpisodes(downloadableEpisodes, actionDelegate: actionDelegate)
                return
            }
            else {
                confirmPicker.addDescriptiveActions(title: L10n.Localizable.download, message: warningMessage, icon: "filter_downloaded", actions: [downloadAction])
            }
        }
        else {
            let queueAction = OptionAction(label: L10n.Localizable.queueForLater, icon: nil) {
                let status = L10n.Localizable.multiSelectQueuingEpisodesFormat(selectedEpisodes.count.localized())
                actionDelegate.multiSelectActionBegan(status: status)
                queueEpisodes(downloadableEpisodes, actionDelegate: actionDelegate)
            }
            
            if !Settings.mobileDataAllowed() {
                warningMessage = L10n.Localizable.downloadDataWarning + "\n" + warningMessage
            }
            confirmPicker.addDescriptiveActions(title: L10n.Localizable.notOnWifi, message: warningMessage, icon: "option-alert", actions: [downloadAction, queueAction])
        }
        
        confirmPicker.show(statusBarStyle: actionDelegate.multiSelectPreferredStatusBarStyle())
    }
    
    private class func downloadEpisodes(_ episodes: [BaseEpisode], actionDelegate: MultiSelectActionDelegate) {
        DispatchQueue.global().async {
            var queuedEpisodes = 0
            for episode in episodes {
                DownloadManager.shared.addToQueue(episodeUuid: episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
                queuedEpisodes += 1
                if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                    return
                }
            }
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func queueEpisodes(_ episodes: [BaseEpisode], actionDelegate: MultiSelectActionDelegate) {
        DispatchQueue.global().async {
            var queuedEpisodes = 0
            for episode in episodes {
                DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
                queuedEpisodes += 1
                if queuedEpisodes == Constants.Limits.maxBulkDownloads {
                    return
                }
            }
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func removeDownload(actionDelegate: MultiSelectActionDelegate) {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        let status = selectedEpisodes.count == 1 ? L10n.Localizable.multiSelectRemoveDownloadSingular : L10n.Localizable.multiSelectRemoveDownloadsPluralFormat(selectedEpisodes.count.localized())
        actionDelegate.multiSelectActionBegan(status: status)
        
        DispatchQueue.global().async {
            EpisodeManager.removeDownloadForEpisodes(selectedEpisodes)
            actionDelegate.multiSelectActionCompleted()
        }
    }
    
    private class func moveToTop(actionDelegate: MultiSelectActionDelegate) {
        guard let selectedPlayListEpisodes = actionDelegate.multiSelectedPlayListEpisodes() else {
            actionDelegate.multiSelectActionCompleted()
            return
        }
        PlaybackManager.shared.queue.bulkMove(selectedPlayListEpisodes, toTop: true)
        actionDelegate.multiSelectActionCompleted()
    }
    
    private class func moveToBottom(actionDelegate: MultiSelectActionDelegate) {
        guard let selectedPlayListEpisodes = actionDelegate.multiSelectedPlayListEpisodes() else {
            actionDelegate.multiSelectActionCompleted()
            return
        }
        PlaybackManager.shared.queue.bulkMove(selectedPlayListEpisodes, toTop: false)
        actionDelegate.multiSelectActionCompleted()
    }
    
    private class func removeFromUpNext(actionDelegate: MultiSelectActionDelegate) {
        guard let selectedUuids = actionDelegate.multiSelectedPlayListEpisodes()?.map(\.episodeUuid) else {
            actionDelegate.multiSelectActionCompleted()
            return
        }
        PlaybackManager.shared.bulkRemoveQueued(uuids: selectedUuids)
        actionDelegate.multiSelectActionCompleted()
    }
    
    // MARK: - Selection Helpers
    
    class func shouldSelectAll(onCount: Int, totalCount: Int) -> Bool {
        onCount < totalCount
    }
    
    // MARK: - Inverse Actions
    
    class func starredAction(actionDelegate: MultiSelectActionDelegate) -> MultiSelectAction {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        for baseEpisode in selectedEpisodes {
            if let episode = baseEpisode as? Episode, !episode.keepEpisode {
                return .star
            }
        }
        return .unstar
    }
    
    class func archiveAction(actionDelegate: MultiSelectActionDelegate) -> MultiSelectAction {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        for baseEpisode in selectedEpisodes {
            if let episode = baseEpisode as? Episode, !episode.archived {
                return .archive
            }
        }
        return .unarchive
    }
    
    class func downloadAction(actionDelegate: MultiSelectActionDelegate) -> MultiSelectAction {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        
        for episode in selectedEpisodes {
            if !episode.downloaded(pathFinder: DownloadManager.shared) {
                return .download
            }
        }
        return .removeDownload
    }
    
    class func markAsPlayedAction(actionDelegate: MultiSelectActionDelegate) -> MultiSelectAction {
        let selectedEpisodes = actionDelegate.multiSelectedBaseEpisodes()
        for episode in selectedEpisodes {
            if !episode.played() {
                return .markAsPlayed
            }
        }
        return .markAsUnplayed
    }
    
    class func invertActionIfRequired(action: MultiSelectAction, actionDelegate: MultiSelectActionDelegate) -> MultiSelectAction {
        if action == .star {
            return MultiSelectHelper.starredAction(actionDelegate: actionDelegate)
        }
        else if action == .archive {
            return MultiSelectHelper.archiveAction(actionDelegate: actionDelegate)
        }
        else if action == .download {
            return MultiSelectHelper.downloadAction(actionDelegate: actionDelegate)
        }
        else if action == .markAsPlayed {
            return MultiSelectHelper.markAsPlayedAction(actionDelegate: actionDelegate)
        }
        return action
    }
}
