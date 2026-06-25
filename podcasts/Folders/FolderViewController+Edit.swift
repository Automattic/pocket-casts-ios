import PocketCastsDataModel
import PocketCastsUtils
import UIKit

extension FolderViewController {
    func setEditingOrder(_ editing: Bool) {
        guard isEditingOrder != editing else { return }
        isEditingOrder = editing

        if editing {
            enterEditMode()
        } else {
            exitEditMode()
        }
    }

    @objc func saveEditingTapped() {
        saveSortOrder()
        setEditingOrder(false)
    }

    func applyEditingTreatment(to cell: UICollectionViewCell) {
        if Settings.libraryType() == .list {
            addReorderHandle(to: cell)
        } else {
            cell.startEditingWiggle()
        }
    }

    func removeEditingTreatment(from cell: UICollectionViewCell) {
        removeReorderHandle(from: cell)
        cell.stopEditingWiggle()
    }

    // MARK: Mode transitions

    private func enterEditMode() {
        savedRightBarButtonItem = customRightBtn

        let saveButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveEditingTapped))
        setCustomRightBtn(saveButton, animated: true)

        mainGrid.dragInteractionEnabled = true
        mainGrid.allowsSelection = false
        setEnclosingTabBarHidden(true, animated: true)

        for cell in mainGrid.visibleCells {
            applyEditingTreatment(to: cell)
        }
    }

    private func exitEditMode() {
        mainGrid.dragInteractionEnabled = false
        mainGrid.allowsSelection = true
        setEnclosingTabBarHidden(false, animated: true)

        setCustomRightBtn(savedRightBarButtonItem, animated: true)
        savedRightBarButtonItem = nil

        for cell in mainGrid.visibleCells {
            removeEditingTreatment(from: cell)
        }
    }

    // MARK: Save

    func saveSortOrder() {
        for (index, podcast) in podcasts.enumerated() {
            podcast.sortOrder = Int32(index)
        }

        DataManager.sharedManager.saveSortOrders(podcasts: podcasts)

        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        folder.sortType = Int32(LibrarySort.Old.custom.rawValue)
        DataManager.sharedManager.save(folder: folder)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)
    }

    // MARK: Reorder handle (list)

    private func addReorderHandle(to cell: UICollectionViewCell) {
        (cell as? PodcastListCell)?.showsReorderHandle = true
    }

    private func removeReorderHandle(from cell: UICollectionViewCell) {
        (cell as? PodcastListCell)?.showsReorderHandle = false
    }
}

extension FolderViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingOrder, let podcast = podcasts[safe: indexPath.item] else {
            return []
        }
        let provider = NSItemProvider(object: podcast.uuid as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = podcast
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        true
    }

    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let dropItem = coordinator.items.first,
              let sourceIndexPath = dropItem.sourceIndexPath,
              podcasts.indices.contains(sourceIndexPath.item) else {
            return
        }
        let rawDestination = coordinator.destinationIndexPath?.item ?? podcasts.count - 1
        let clampedDestination = min(max(0, rawDestination), podcasts.count - 1)
        let destinationIndexPath = IndexPath(item: clampedDestination, section: 0)

        collectionView.performBatchUpdates {
            let moved = podcasts.remove(at: sourceIndexPath.item)
            podcasts.insert(moved, at: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        }
        coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
    }
}
