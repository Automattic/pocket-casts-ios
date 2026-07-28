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
            castCell.populateFrom(podcast: podcast, badgeType: badgeType, libraryType: libraryType)
        }

        // Keep the reorder-edit treatment in sync so reused/recycled cells stay correct.
        if isEditingOrder {
            applyEditingTreatment(to: cell)
        } else {
            removeEditingTreatment(from: cell)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let podcast = podcasts[safe: indexPath.row] else { return }

        NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
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
