import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit

extension PodcastListViewController {
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        // While editing the order, taps and gestures are reserved for drag-to-reorder.
        guard !isEditingOrder, let item = itemAt(indexPath: indexPath), !item.isEmpty else {
            return nil
        }
        if let podcast = item.podcast {
            return makePodcastContextMenu(for: podcast, at: indexPath)
        }
        if let folder = item.folder {
            return makeFolderContextMenu(for: folder, at: indexPath)
        }
        return nil
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

    private func makeFolderContextMenu(for folder: Folder, at indexPath: IndexPath) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: {
                FolderPreviewViewController(folder: folder)
            },
            actionProvider: { [weak self] _ in
                self?.makeFolderMenu(for: folder)
            }
        )
    }

    // MARK: Menus

    private func makePodcastMenu(for podcast: Podcast, at indexPath: IndexPath) -> UIMenu {
        let shareAction = UIAction(title: L10n.share, image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            guard let self else { return }
            let cell = self.podcastsCollectionView.cellForItem(at: indexPath)
            let sourceRect = cell.map { self.podcastsCollectionView.convert($0.frame, to: self.view) } ?? .zero
            SharingHelper.shared.shareLinkTo(podcast: podcast,
                                             fromController: self,
                                             fromSource: self.analyticsSource,
                                             sourceRect: sourceRect,
                                             sourceView: self.view)
        }
        let addToFolderAction = UIAction(title: L10n.folderAddTo, image: UIImage(systemName: "folder.badge.plus")) { [weak self] _ in
            self?.showFolderPicker(for: podcast)
        }
        let topRow = UIMenu(title: "", options: .displayInline, preferredElementSize: .medium, children: [shareAction, addToFolderAction])

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

    private func makeFolderMenu(for folder: Folder) -> UIMenu {
        let editFolderAction = UIAction(title: L10n.folderEdit, image: UIImage(systemName: "folder")) { [weak self] _ in
            self?.openFolderEdit(folder: folder)
        }
        let editAction = UIAction(title: L10n.edit, image: UIImage(systemName: "arrow.up.arrow.down")) { [weak self] _ in
            self?.setEditingOrder(true)
        }
        return UIMenu(title: "", children: [editFolderAction, editAction])
    }

    // MARK: Action handlers

    private func confirmUnsubscribe(podcast: Podcast) {
        let label = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let alert = UIAlertController(title: L10n.areYouSure, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: label, style: .destructive) { [weak self] _ in
            PodcastManager.shared.unsubscribe(podcast: podcast)
            Analytics.track(.podcastUnsubscribed, properties: ["source": self?.analyticsSource ?? AnalyticsSource.podcastsList, "uuid": podcast.uuid])
        })
        present(alert, animated: true)
    }

    private func showFolderPicker(for podcast: Podcast) {
        if !SubscriptionHelper.hasActiveSubscription() {
            NavigationManager.sharedManager.showUpsellView(from: self, source: .folders)
            return
        }

        let model = ChoosePodcastFolderModel(pickingFor: podcast.uuid, currentFolder: podcast.folderUuid)
        let chooseFolderView = ChoosePodcastFolderView(model: model) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        let hostingController = PCHostingController(rootView: chooseFolderView.environmentObject(Theme.sharedTheme))
        present(hostingController, animated: true)
    }

    private func openFolderEdit(folder: Folder) {
        let model = FolderModel(saveOnChange: true)
        model.name = folder.name
        model.colorInt = Int(folder.color)
        model.folderUuid = folder.uuid
        let editFolderView = EditFolderView(model: model) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        let hostingController = PCHostingController(rootView: editFolderView.environmentObject(Theme.sharedTheme))
        present(hostingController, animated: true)
    }
}
