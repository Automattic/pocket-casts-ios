import PocketCastsDataModel
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
            previewProvider: { [weak self] in
                self?.makePodcastPreviewController(uuid: podcast.uuid)
            },
            actionProvider: { [weak self] _ in
                self?.makePodcastMenu(for: podcast, at: indexPath)
            }
        )
    }

    private func makeFolderContextMenu(for folder: Folder, at indexPath: IndexPath) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: { [weak self] in
                self?.makeFolderPreviewController(folder: folder)
            },
            actionProvider: { [weak self] _ in
                self?.makeFolderMenu(for: folder)
            }
        )
    }

    // MARK: Preview controllers

    private func makePodcastPreviewController(uuid: String) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])

        ImageManager.sharedManager.loadImage(podcastUuid: uuid, imageView: imageView, size: .page, showPlaceHolder: true)
        viewController.preferredContentSize = CGSize(width: 280, height: 280)
        return viewController
    }

    private func makeFolderPreviewController(folder: Folder) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear

        let folderColor = AppTheme.folderColor(colorInt: folder.color)
        let backdrop = UIView()
        backdrop.backgroundColor = folderColor
        backdrop.layer.cornerRadius = 8
        backdrop.layer.masksToBounds = true
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(backdrop)

        let label = UILabel()
        label.text = folder.name
        label.textColor = ThemeColor.filterText01(filterColor: folderColor)
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(label)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: backdrop.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: backdrop.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: backdrop.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: backdrop.trailingAnchor, constant: -16)
        ])

        viewController.preferredContentSize = CGSize(width: 280, height: 280)
        return viewController
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

        let notificationsOn = podcast.isPushEnabled
        let onAction = UIAction(title: L10n.on, state: notificationsOn ? .on : .off) { _ in
            if !notificationsOn {
                PodcastManager.shared.setNotificationsEnabled(podcast: podcast, enabled: true)
            }
        }
        let offAction = UIAction(title: L10n.off, state: notificationsOn ? .off : .on) { _ in
            if notificationsOn {
                PodcastManager.shared.setNotificationsEnabled(podcast: podcast, enabled: false)
            }
        }
        let notificationsMenu = UIMenu(title: L10n.settingsNotifications,
                                       image: UIImage(systemName: notificationsOn ? "bell" : "bell.slash"),
                                       options: .singleSelection,
                                       children: [onAction, offAction])

        let editAction = UIAction(title: L10n.edit, image: UIImage(systemName: "arrow.up.arrow.down")) { [weak self] _ in
            self?.setEditingOrder(true)
        }
        let editSection = UIMenu(title: "", options: .displayInline, children: [editAction])

        let unfollowTitle = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let unfollowAction = UIAction(title: unfollowTitle, image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.confirmUnsubscribe(podcast: podcast)
        }

        return UIMenu(title: "", children: [topRow, notificationsMenu, editSection, unfollowAction])
    }

    private func makeFolderMenu(for folder: Folder) -> UIMenu {
        let editFolderAction = UIAction(title: L10n.folderEdit, image: UIImage(systemName: "folder")) { [weak self] _ in
            self?.openFolderEdit(folder: folder)
        }
        let addRemoveAction = UIAction(title: L10n.folderAddRemovePodcasts, image: UIImage(systemName: "plus.rectangle.on.folder")) { [weak self] _ in
            self?.openFolderPodcastSelection(folder: folder)
        }
        let editMenu = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: L10n.edit, image: UIImage(systemName: "arrow.up.arrow.down")) { [weak self] _ in
                self?.setEditingOrder(true)
            }
        ])
        return UIMenu(title: "", children: [editFolderAction, addRemoveAction, editMenu])
    }

    // MARK: Action handlers

    private func confirmUnsubscribe(podcast: Podcast) {
        let optionPicker = OptionsPicker(title: L10n.areYouSure)
        let label = FeatureFlag.useFollowNaming.enabled ? L10n.unfollow : L10n.unsubscribe
        let action = OptionAction(label: label, icon: nil) {
            PodcastManager.shared.unsubscribe(podcast: podcast)
        }
        action.destructive = true
        optionPicker.addAction(action: action)
        optionPicker.show(statusBarStyle: preferredStatusBarStyle)
    }

    private func showFolderPicker(for podcast: Podcast) {
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

    private func openFolderPodcastSelection(folder: Folder) {
        let model = FolderModel(saveOnChange: true)
        model.name = folder.name
        model.colorInt = Int(folder.color)
        model.folderUuid = folder.uuid
        model.selectedPodcastUuids = DataManager.sharedManager.allPodcastsInFolder(folder: folder).map(\.uuid)
        let editFoldersView = EditFolderPodcastsView(model: model) { [weak self] in
            self?.dismiss(animated: true)
        }
        let hostingController = PCHostingController(rootView: editFoldersView.environmentObject(Theme.sharedTheme))
        present(hostingController, animated: true)
    }
}
