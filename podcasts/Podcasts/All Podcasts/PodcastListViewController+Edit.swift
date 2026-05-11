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
        Analytics.track(.podcastsListReordered)
        setEditingOrder(false)
    }

    @objc func cancelEditingTapped() {
        if let snapshot = orderBeforeEditing, snapshot != gridItems {
            gridItems = snapshot
            podcastsCollectionView.reloadData()
        }
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
        savedLeftBarButtonItem = navigationItem.leftBarButtonItem
        savedRightBarButtonItem = customRightBtn

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelEditingTapped))
        customRightBtn = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveEditingTapped))

        orderBeforeEditing = gridItems
        podcastsCollectionView.dragInteractionEnabled = true
        setTabBarHidden(true, animated: true)

        for cell in podcastsCollectionView.visibleCells {
            applyEditingTreatment(to: cell)
        }
    }

    private func exitEditMode() {
        orderBeforeEditing = nil
        podcastsCollectionView.dragInteractionEnabled = false
        setTabBarHidden(false, animated: true)

        navigationItem.leftBarButtonItem = savedLeftBarButtonItem
        customRightBtn = savedRightBarButtonItem
        savedLeftBarButtonItem = nil
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

    private static let reorderHandleTag = 0x504C5648 // "PLVH"

    private func addReorderHandle(to cell: UICollectionViewCell) {
        guard cell.contentView.viewWithTag(Self.reorderHandleTag) == nil else { return }
        let handle = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        handle.tag = Self.reorderHandleTag
        handle.tintColor = ThemeColor.primaryIcon02()
        handle.contentMode = .center
        handle.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            handle.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            handle.widthAnchor.constraint(equalToConstant: 24),
            handle.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func removeReorderHandle(from cell: UICollectionViewCell) {
        cell.contentView.viewWithTag(Self.reorderHandleTag)?.removeFromSuperview()
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
              let sourceIndexPath = dropItem.sourceIndexPath else {
            return
        }
        let destinationIndexPath = coordinator.destinationIndexPath
            ?? IndexPath(item: max(0, gridItems.count - 1), section: 0)

        collectionView.performBatchUpdates {
            let moved = gridItems.remove(at: sourceIndexPath.item)
            gridItems.insert(moved, at: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        }
        coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
    }
}
