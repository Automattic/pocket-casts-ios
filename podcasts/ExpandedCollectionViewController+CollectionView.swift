extension ExpandedCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        podcasts.count
    }

    // MARK: - CollectionView Datasource

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch cellStyle {
        case .grid:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpandedCollectionViewController.gridCellId, for: indexPath) as! LargeListCell
            let thisPodcast = podcasts[indexPath.row]
            if let delegate = delegate {
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
            if let delegate = delegate {
                cell.populateFrom(thisPodcast, isSubscribed: delegate.isSubscribed(podcast: thisPodcast))
                cell.onSubscribe = { [weak self] in
                    if let listId = self?.item.uuid, let podcastUuid = thisPodcast.uuid {
                        AnalyticsHelper.podcastSubscribedFromList(listId: listId, podcastUuid: podcastUuid)
                    }
                    delegate.subscribe(podcast: thisPodcast)
                }
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let podcast = podcasts[indexPath.row]
        delegate?.show(discoverPodcast: podcast, placeholderImage: nil, isFeatured: false, listUuid: item.uuid)
        collectionView.deselectItem(at: indexPath, animated: true)

        if let listId = item.uuid, let podcastUuid = podcast.uuid {
            AnalyticsHelper.podcastTappedFromList(listId: listId, podcastUuid: podcastUuid)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard podcastCollection != nil else { return CGSize.zero }

        let headerView: DiscoverCollectionHeader = DiscoverCollectionHeader.fromNib()
        headerView.populate(podcastCollection: podcastCollection)
        headerView.linkDelegate = self

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
        if viewWidth < bigDevicePortraitWidth {
            switch cellStyle {
            case .descriptive_list:
                return CGSize(width: viewWidth, height: descriptiveListPreferredMaxHeight)
            case .grid:
                let itemWidth = (viewWidth - (gridStyleSpacing * (gridNumColumns - 1))) / gridNumColumns
                let itemHeight = itemWidth + 60
                return CGSize(width: itemWidth, height: itemHeight)
            }
        } else {
            switch cellStyle {
            case .descriptive_list:
                let numColumns = floor(viewWidth / (descriptiveListPreferredMaxWidth + descriptiveListSpacing))
                let itemWidth = (viewWidth - (descriptiveListSpacing * (numColumns - 1))) / numColumns
                return CGSize(width: itemWidth, height: descriptiveListPreferredMaxHeight)
            case .grid:
                let numColumns = floor(viewWidth / (gridPreferredWidth + gridStyleSpacing))
                let itemWidth = (viewWidth - (gridStyleSpacing * (numColumns - 1))) / numColumns
                let itemHeight = itemWidth + 60
                return CGSize(width: itemWidth, height: itemHeight)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let topInset = (podcastCollection == nil && cellStyle == .grid) ? inset : 0
        return UIEdgeInsets(top: topInset, left: inset, bottom: 0, right: inset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch cellStyle {
        case .descriptive_list:
            return 0
        case .grid:
            return inset
        }
    }

    func updateFlowLayoutSize() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout() // force the elements to get laid out again with the new size
        }
    }
}
