import UIKit

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
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        }
        coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)

        Analytics.track(.podcastsListReordered)
        saveSortOrder()
    }
}
