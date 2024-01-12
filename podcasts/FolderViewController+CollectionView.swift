import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension FolderViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private static let podcastCellId = "PodcastGridCell"
    private static let podcastListCellId = "PodcastListCell"

    func registerCells() {
        mainGrid.register(UINib(nibName: "PodcastGridCell", bundle: nil), forCellWithReuseIdentifier: FolderViewController.podcastCellId)
        mainGrid.register(UINib(nibName: "PodcastListCell", bundle: nil), forCellWithReuseIdentifier: FolderViewController.podcastListCellId)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if Settings.libraryType() == .list {
            return collectionView.dequeueReusableCell(withReuseIdentifier: FolderViewController.podcastListCellId, for: indexPath)
        }

        return collectionView.dequeueReusableCell(withReuseIdentifier: FolderViewController.podcastCellId, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let podcast = podcasts[safe: indexPath.row] else { return }

        let libraryType = Settings.libraryType()
        let badgeType = Settings.podcastBadgeType()

        if libraryType == .list {
            let castCell = cell as! PodcastListCell
            castCell.populateFrom(podcast, badgeType: badgeType)
        } else {
            let castCell = cell as! PodcastGridCell
            castCell.accessibilityIdentifier = "GridCell-\(podcast.uuid)"
            castCell.populateFrom(podcast: podcast, badgeType: badgeType, libraryType: libraryType)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let podcast = podcasts[safe: indexPath.row] else { return }

        NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
    }

    // MARK: - Re-ordering

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let podcastToMove = podcasts[safe: sourceIndexPath.row] else { return }

        if let index = podcasts.firstIndex(of: podcastToMove) {
            podcasts.remove(at: index)
            podcasts.insert(podcastToMove, at: destinationIndexPath.row)

            saveSortOrder()
        }
    }

    private func saveSortOrder() {
        for (index, podcast) in podcasts.enumerated() {
            podcast.sortOrder = Int32(index)
        }

        DataManager.sharedManager.saveSortOrders(podcasts: podcasts)

        folder.syncModified = TimeFormatter.currentUTCTimeInMillis()
        folder.sortType = Int32(LibrarySort.custom.rawValue)
        DataManager.sharedManager.save(folder: folder)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.folderChanged, object: folder.uuid)
    }

    // MARK: - Row Sizing

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        gridHelper.collectionView(collectionView, sizeForItemAt: indexPath, itemCount: podcasts.count)
    }

    func updateFlowLayoutSize() {
        guard let flowLayout = mainGrid.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        flowLayout.invalidateLayout() // force the elements to get laid out again with the new size
    }
}
