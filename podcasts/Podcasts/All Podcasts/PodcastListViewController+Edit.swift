import UIKit

extension PodcastListViewController {
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
            startWiggle(on: cell)
        }
    }

    func removeEditingTreatment(from cell: UICollectionViewCell) {
        removeReorderHandle(from: cell)
        stopWiggle(on: cell)
    }

    // MARK: Mode transitions

    private func enterEditMode() {
        savedRightBarButtonItem = customRightBtn

        let saveButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveEditingTapped))
        setCustomRightBtn(saveButton, animated: true)

        podcastsCollectionView.dragInteractionEnabled = true
        podcastsCollectionView.allowsSelection = false
        setTabBarHidden(true, animated: true)

        for cell in podcastsCollectionView.visibleCells {
            applyEditingTreatment(to: cell)
        }
    }

    private func exitEditMode() {
        podcastsCollectionView.dragInteractionEnabled = false
        podcastsCollectionView.allowsSelection = true
        setTabBarHidden(false, animated: true)

        setCustomRightBtn(savedRightBarButtonItem, animated: true)
        savedRightBarButtonItem = nil

        for cell in podcastsCollectionView.visibleCells {
            removeEditingTreatment(from: cell)
        }
    }

    private func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard #available(iOS 18.0, *), let tabBarController else { return }
        tabBarController.setTabBarHidden(hidden, animated: animated)
    }

    // MARK: Wiggle (grid)

    private static let wiggleAnimationKey = "podcasts.editingWiggle"

    private func startWiggle(on cell: UICollectionViewCell) {
        guard cell.layer.animation(forKey: Self.wiggleAnimationKey) == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [-0.012, 0.012, -0.012]
        animation.duration = 0.28
        animation.repeatCount = .infinity
        animation.timeOffset = .random(in: 0...animation.duration) // stagger so cells don't move in unison
        cell.layer.add(animation, forKey: Self.wiggleAnimationKey)
    }

    private func stopWiggle(on cell: UICollectionViewCell) {
        cell.layer.removeAnimation(forKey: Self.wiggleAnimationKey)
    }

    // MARK: Reorder handle (list)

    private func addReorderHandle(to cell: UICollectionViewCell) {
        (cell as? PodcastListCell)?.showsReorderHandle = true
        (cell as? FolderListCell)?.showsReorderHandle = true
    }

    private func removeReorderHandle(from cell: UICollectionViewCell) {
        (cell as? PodcastListCell)?.showsReorderHandle = false
        (cell as? FolderListCell)?.showsReorderHandle = false
    }
}

extension PodcastListViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingOrder, let item = itemAt(indexPath: indexPath), !item.isEmpty else {
            return []
        }
        let provider = NSItemProvider(object: (item.podcast?.uuid ?? item.folder?.uuid ?? "") as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item
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
              gridItems.indices.contains(sourceIndexPath.item) else {
            return
        }
        let rawDestination = coordinator.destinationIndexPath?.item ?? gridItems.count - 1
        let clampedDestination = min(max(0, rawDestination), gridItems.count - 1)
        let destinationIndexPath = IndexPath(item: clampedDestination, section: 0)

        collectionView.performBatchUpdates {
            let moved = gridItems.remove(at: sourceIndexPath.item)
            gridItems.insert(moved, at: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        }
        coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
        Analytics.track(.podcastsListReordered)
    }
}
