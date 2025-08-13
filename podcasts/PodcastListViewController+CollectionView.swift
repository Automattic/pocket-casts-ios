import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import SwiftUI
import PocketCastsServer

extension PodcastListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private static let podcastSquareCellId = "PodcastGridCell"
    private static let podcastListCellId = "PodcastListCell"
    private static let folderSquareCellId = "FolderGridCell"
    private static let folderListCellId = "FolderListCell"
    private static let bannerAdHeaderId = "BannerAdHeader"
    private static let emptyStateCellId = "EmptyStateCell"

    func registerCells() {
        podcastsCollectionView.register(UINib(nibName: "PodcastGridCell", bundle: nil), forCellWithReuseIdentifier: PodcastListViewController.podcastSquareCellId)
        podcastsCollectionView.register(UINib(nibName: "PodcastListCell", bundle: nil), forCellWithReuseIdentifier: PodcastListViewController.podcastListCellId)
        podcastsCollectionView.register(UINib(nibName: "FolderGridCell", bundle: nil), forCellWithReuseIdentifier: PodcastListViewController.folderSquareCellId)
        podcastsCollectionView.register(UINib(nibName: "FolderListCell", bundle: nil), forCellWithReuseIdentifier: PodcastListViewController.folderListCellId)
        podcastsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: PodcastListViewController.emptyStateCellId)

        // Register header view for banner ads
        podcastsCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PodcastListViewController.bannerAdHeaderId)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemCount()
    }

    private func makeEmptyStateView() -> EmptyStateView<Text, DefaultEmptyStateStyle> {
        EmptyStateView(
            title: L10n.podcastGridNoPodcastsTitle,
            message: L10n.podcastGridNoPodcastsMsg,
            icon: { Image("podcastlist_smallgrid").renderingMode(.template) },
            actions: [
                .init(title: L10n.podcastGridDiscoverPodcasts, action: {
                    Analytics.shared.track(.podcastsListDiscoverButtonTapped)
                    NavigationManager.sharedManager.navigateTo(NavigationManager.discoverPageKey)
                })
            ],
            style: DefaultEmptyStateStyle.defaultStyle
        )
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let libraryType = Settings.libraryType()
        let item = itemAt(indexPath: indexPath)

        if item?.isEmpty == true {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PodcastListViewController.emptyStateCellId, for: indexPath)
            cell.contentConfiguration = UIHostingConfiguration {
                makeEmptyStateView()
            }
            .margins(.horizontal, 16)
            .margins(.vertical, 8)
            return cell
        }

        if libraryType == .list {
            if item?.podcast != nil {
                return collectionView.dequeueReusableCell(withReuseIdentifier: PodcastListViewController.podcastListCellId, for: indexPath)
            } else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: PodcastListViewController.folderListCellId, for: indexPath)
            }
        }
        if item?.podcast != nil {
            return collectionView.dequeueReusableCell(withReuseIdentifier: PodcastListViewController.podcastSquareCellId, for: indexPath)
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: PodcastListViewController.folderSquareCellId, for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let item = itemAt(indexPath: indexPath) else { return }

        let libraryType = Settings.libraryType()
        let badgeType = Settings.podcastBadgeType()

        if libraryType == .list {
            if let podcast = item.podcast {
                let castCell = cell as! PodcastListCell
                castCell.populateFrom(podcast, badgeType: badgeType)
            } else if let folder = item.folder {
                let castCell = cell as! FolderListCell
                castCell.populateFrom(folder: folder, badgeType: badgeType)
            }
        } else {
            if let podcast = item.podcast {
                let castCell = cell as! PodcastGridCell
                castCell.populateFrom(podcast: podcast, badgeType: badgeType, libraryType: libraryType)
            } else if let folder = item.folder {
                let castCell = cell as! FolderGridCell
                castCell.populateFrom(folder: folder, badgeType: badgeType, libraryType: libraryType)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let selectedItem = itemAt(indexPath: indexPath)

        if selectedItem?.isEmpty == true {
            return
        }

        if let podcast = selectedItem?.podcast {
            Analytics.track(.podcastsListPodcastTapped)
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
        } else if let folder = selectedItem?.folder {
            Analytics.track(.podcastsListFolderTapped)
            NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
        }
    }

    // MARK: - Re-ordering

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let itemBeingMoved = gridItems[safe: sourceIndexPath.row] else { return }

        if let index = gridItems.firstIndex(of: itemBeingMoved) {
            gridItems.remove(at: index)
            gridItems.insert(itemBeingMoved, at: destinationIndexPath.row)

            Analytics.track(.podcastsListReordered)

            saveSortOrder()
        }
    }

    private func saveSortOrder() {
        for (index, listItem) in gridItems.enumerated() {
            if let podcast = listItem.podcast {
                podcast.sortOrder = Int32(index)
            } else if let folder = listItem.folder {
                folder.sortOrder = Int32(index)
            }
        }

        let allPodcasts = gridItems.compactMap(\.podcast)
        let allFolders = gridItems.compactMap(\.folder)

        DataManager.sharedManager.saveSortOrders(podcasts: allPodcasts)
        DataManager.sharedManager.saveSortOrders(folders: allFolders, syncModified: TimeFormatter.currentUTCTimeInMillis())
        Settings.setHomeFolderSortOrder(order: .custom)
    }

    // MARK: - Row Sizing

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = itemAt(indexPath: indexPath)
        if item?.isEmpty == true {
            let sizingView = makeEmptyStateView()
                .environmentObject(Theme.sharedTheme)

            let hostingController = UIHostingController(rootView: sizingView)
            let targetSize = CGSize(width: collectionView.bounds.width - 32, height: UIView.layoutFittingCompressedSize.height)
            let size = hostingController.sizeThatFits(in: targetSize)

            return CGSize(width: collectionView.bounds.width, height: size.height)
        }
        return gridHelper.collectionView(collectionView, sizeForItemAt: indexPath, itemCount: itemCount())
    }

    func updateFlowLayoutSize() {
        if let flowLayout = podcastsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout() // force the elements to get laid out again with the new size
        }
    }

    // MARK: - Supplementary Views

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PodcastListViewController.bannerAdHeaderId, for: indexPath)

            // Remove existing subviews
            headerView.subviews.forEach { $0.removeFromSuperview() }

            if let bannerAdModel = bannerAdModel {
                let bannerAdView = bannerAdView(bannerAdModel: bannerAdModel)
                let hostingController = PCHostingController(rootView: bannerAdView)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                hostingController.view.backgroundColor = .clear

                headerView.addSubview(hostingController.view)
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
                ])

                hostingController.view.alpha = 0

                // Set initial position constraint
                let topConstraint = hostingController.view.topAnchor.constraint(equalTo: headerView.topAnchor, constant: -120)
                topConstraint.isActive = true

                headerView.layoutIfNeeded()

                // Set alpha to 0 after layout is complete
                DispatchQueue.main.async {

                    // Animate the banner down first
                    UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
                        topConstraint.constant = 0
                        headerView.layoutIfNeeded()
                    }

                    // Animate opacity second so it's more noticeable
                    UIView.animate(withDuration: 0.2, delay: 0.05) {
                        hostingController.view.alpha = 1
                    }
                }
            }

            return headerView
        }

        return UICollectionReusableView()
    }

    private func bannerAdView(bannerAdModel: BannerAdModel) -> some View {
        let backgroundColor = (podcastsCollectionView as? ThemeableCollectionView)!.style
        let isSameColor = ThemeColor.secondaryUi01() == AppTheme.colorForStyle(backgroundColor)

        let additionalPadding: CGFloat = Settings.libraryType() == .list ? 16 : 0

        return BannerAdView(model: bannerAdModel, colors: .podcastList(Theme.sharedTheme))
            .padding(.top, !isSameColor ? 16 : 0)
            .padding(.bottom, additionalPadding)
            .padding(.horizontal, additionalPadding)
            .environmentObject(Theme.sharedTheme)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let bannerAdModel else {
            return .zero
        }

        // Use a separate view because fetching the view from UICollectionView isn't allowed until view is part of window hierarchy.
        let sizingView = bannerAdView(bannerAdModel: bannerAdModel)

        let hostingController = UIHostingController(rootView: sizingView)
        let targetSize = CGSize(width: collectionView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = hostingController.sizeThatFits(in: targetSize)

        // Return zero height initially for animation, then full size after animation starts
        return isAnimatingBannerAd ? .zero : size
    }
}
