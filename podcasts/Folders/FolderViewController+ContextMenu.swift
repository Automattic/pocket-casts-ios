import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension FolderViewController {
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        // While editing the order, taps and gestures are reserved for drag-to-reorder.
        guard !isEditingOrder, let podcast = podcasts[safe: indexPath.item] else {
            return nil
        }
        return makePodcastContextMenu(for: podcast, at: indexPath)
    }

    // MARK: Configuration builders

    private func makePodcastContextMenu(for podcast: Podcast, at indexPath: IndexPath) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: {
                PodcastPreviewViewController(podcastUUID: podcast.uuid)
            },
            actionProvider: { [weak self] _ in
                self?.makePodcastMenu(for: podcast, at: indexPath)
            }
        )
    }

    // MARK: Menus

    private func makePodcastMenu(for podcast: Podcast, at indexPath: IndexPath) -> UIMenu {
        let shareAction = UIAction(title: L10n.share, image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self else { return }
            let cell = self.mainGrid.cellForItem(at: indexPath)
            let sourceRect = cell.map { self.mainGrid.convert($0.frame, to: self.view) } ?? .zero
            SharingHelper.shared.shareLinkTo(podcast: podcast,
                                             fromController: self,
                                             fromSource: .folder,
                                             sourceRect: sourceRect,
                                             sourceView: self.view)
        }
        let removeFromFolderAction = UIAction(title: L10n.folderRemoveFrom, image: UIImage(systemName: "folder.badge.minus")) { [weak self] _ in
            self?.removeFromFolder(podcast: podcast)
        }
        let topRow = UIMenu(title: "", options: .displayInline, preferredElementSize: .medium, children: [shareAction, removeFromFolderAction])

        let notificationsOn = podcast.pushEnabled
        let onAction = UIAction(title: L10n.on, state: notificationsOn ? .on : .off) { _ in
            if !notificationsOn {
                Analytics.track(.podcastsListNotificationsTapped, properties: ["enabled": true])
                NotificationsHelper.shared.setNotificationsEnabled(true, for: podcast)
            }
        }
        let offAction = UIAction(title: L10n.off, state: notificationsOn ? .off : .on) { _ in
            if notificationsOn {
                Analytics.track(.podcastsListNotificationsTapped, properties: ["enabled": false])
                NotificationsHelper.shared.setNotificationsEnabled(false, for: podcast)
            }
        }
        let notificationsMenu = UIMenu(title: notificationsOn ? L10n.notificationsOn : L10n.notificationsOff,
                                       image: UIImage(systemName: notificationsOn ? "bell" : "bell.slash"),
                                       options: .singleSelection,
                                       children: [onAction, offAction])

        let editAction = UIAction(title: L10n.podcastsEdit, image: UIImage(systemName: "arrow.up.arrow.down")) { [weak self] _ in
            self?.setEditingOrder(true)
        }

        let unfollowTitle = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let unfollowAction = UIAction(title: unfollowTitle, image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.confirmUnsubscribe(podcast: podcast)
        }

        return UIMenu(title: "", children: [topRow, notificationsMenu, editAction, unfollowAction])
    }

    // MARK: Action handlers

    private func removeFromFolder(podcast: Podcast) {
        podcast.sortOrder = ServerPodcastManager.shared.highestSortOrderForHomeGrid() + 1
        podcast.folderUuid = nil
        podcast.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(podcast: podcast)

        DataManager.sharedManager.updateFolderSyncModified(folderUuid: folder.uuid, syncModified: TimeFormatter.currentUTCTimeInMillis())

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)

        Analytics.track(.folderPodcastModalOptionTapped, properties: ["option": "remove"])
    }

    private func confirmUnsubscribe(podcast: Podcast) {
        let label = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let alert = UIAlertController(title: L10n.areYouSure, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: label, style: .destructive) { _ in
            PodcastManager.shared.unsubscribe(podcast: podcast)
            Analytics.track(.podcastUnsubscribed, properties: ["source": AnalyticsSource.folder, "uuid": podcast.uuid])
        })
        present(alert, animated: true)
    }
}
