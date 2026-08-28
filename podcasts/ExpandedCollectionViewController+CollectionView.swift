import SwiftUI

extension ExpandedCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellStyle == .networkGrid ? networks.count : podcasts.count
    }

    // MARK: - CollectionView Datasource

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch cellStyle {
        case .grid:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpandedCollectionViewController.gridCellId, for: indexPath) as! LargeListCell
            let thisPodcast = podcasts[indexPath.row]
            if let delegate {
                cell.populateFrom(thisPodcast, isSubscribed: delegate.isSubscribed(podcast: thisPodcast))
                cell.onSubscribe = { [weak self] in
                    if let listId = self?.item.uuid, let podcastUuid = thisPodcast.uuid {
                        AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
                    }
                    delegate.subscribe(podcast: thisPodcast)
                }
            }
            return cell
        case .descriptive_list:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpandedCollectionViewController.descriptiveCellId, for: indexPath) as! DescriptiveCollectionCell
            let thisPodcast = podcasts[indexPath.row]
            if let delegate {
                cell.populateFrom(thisPodcast, isSubscribed: delegate.isSubscribed(podcast: thisPodcast))
                cell.onSubscribe = { [weak self] in
                    if let listId = self?.item.uuid, let podcastUuid = thisPodcast.uuid {
                        AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
                    }
                    delegate.subscribe(podcast: thisPodcast)
                }
            }
            return cell
        case .networkGrid:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpandedCollectionViewController.networkCellId, for: indexPath)
            let network = networks[indexPath.row]
            cell.contentConfiguration = UIHostingConfiguration {
                DiscoverNetworkPoster(network: network)
            }
            .margins(.all, 0)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if cellStyle == .networkGrid {
            onSelectNetwork?(networks[indexPath.row])
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        let podcast = podcasts[indexPath.row]
        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: item.uuid)
        collectionView.deselectItem(at: indexPath, animated: true)

        if let listId = item.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard podcastCollection != nil else { return CGSize.zero }

        // swiftlint:disable:next redundant_type_annotation
        let headerView: DiscoverCollectionHeader = DiscoverCollectionHeader.fromNib()
        headerView.populate(podcastCollection: podcastCollection)

        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                  withHorizontalFittingPriority: .required, // Width is fixed
                                                  verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ExpandedCollectionViewController.headerId, for: indexPath) as! DiscoverCollectionHeader
        header.populate(podcastCollection: podcastCollection)
        header.linkDelegate = self
        return header
    }

    // Sizing functions
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidth = collectionView.bounds.width - (2 * inset)
        let isBigDevice = viewWidth >= bigDevicePortraitWidth

        switch cellStyle {
        case .descriptive_list:
            guard isBigDevice else {
                return CGSize(width: viewWidth, height: descriptiveListPreferredMaxHeight)
            }
            let numColumns = floor(viewWidth / (descriptiveListPreferredMaxWidth + descriptiveListSpacing))
            let itemWidth = (viewWidth - (descriptiveListSpacing * (numColumns - 1))) / numColumns
            return CGSize(width: itemWidth, height: descriptiveListPreferredMaxHeight)
        case .grid:
            let numColumns = isBigDevice ? floor(viewWidth / (gridPreferredWidth + gridStyleSpacing)) : gridNumColumns
            let itemWidth = (viewWidth - (gridStyleSpacing * (numColumns - 1))) / numColumns
            return CGSize(width: itemWidth, height: itemWidth + cellExtraHeight)
        case .networkGrid:
            return networkItemSize(in: collectionView)
        }
    }

    /// Network posters are square: unlike a podcast, the title is drawn over the artwork.
    func networkItemSize(in collectionView: UICollectionView) -> CGSize {
        let viewWidth = collectionView.bounds.width - (2 * inset)
        let numColumns = max(gridNumColumns, floor(viewWidth / (networkGridPreferredWidth + gridStyleSpacing)))
        let itemWidth = (viewWidth - (gridStyleSpacing * (numColumns - 1))) / numColumns

        return CGSize(width: itemWidth, height: itemWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let topInset = (podcastCollection == nil && cellStyle != .descriptive_list) ? inset : 0
        return UIEdgeInsets(top: topInset, left: inset, bottom: 0, right: inset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch cellStyle {
        case .descriptive_list:
            return 0
        case .grid, .networkGrid:
            return inset
        }
    }

    func updateFlowLayoutSize() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout() // force the elements to get laid out again with the new size
        }
    }
}
