// All code needed for hooking up the search bar and related functionality to DiscoverCollectionViewController

extension DiscoverCollectionViewController {
    func setupSearchBar() {
        collectionView.delegate = self // For the UIScrollViewDelegate callbacks

        addCustomObserver(Constants.Notifications.chartRegionChanged, selector: #selector(chartRegionDidChange))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        searchController.install(in: self, attachedTo: collectionView)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self
    }
}

extension DiscoverCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchResultsController.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = dataSource.itemIdentifier(for: indexPath)

        switch item {
        case .item(let item):
            let viewController = (cell.contentConfiguration as? UIViewControllerContentConfiguration)?.viewController as? DiscoverSummaryProtocol & UIViewController
            viewController?.populateFrom(item: item.model.item, region: item.model.region, category: item.model.selectedCategory)
            viewController?.beginAppearanceTransition(true, animated: false)
            viewController?.endAppearanceTransition()
        default:
            ()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        let viewController = (cell.contentConfiguration as? UIViewControllerContentConfiguration)?.viewController
        viewController?.beginAppearanceTransition(false, animated: false)
        viewController?.endAppearanceTransition()
    }
}

extension DiscoverCollectionViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        guard let searchView = searchResultsController.view, searchView.superview == nil else {
            return
        }

        searchView.alpha = 0
        addChild(searchResultsController)
        // Manually drive appearance because `shouldAutomaticallyForwardAppearanceMethods` is `false`;
        // without this the hosting controller's SwiftUI view doesn't pick up the parent's bottom safe area,
        // so search results scroll under the mini player.
        searchResultsController.beginAppearanceTransition(true, animated: false)
        view.addSubview(searchView)
        searchResultsController.didMove(toParent: self)


        searchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            searchView.topAnchor.constraint(equalTo: searchController.view.bottomAnchor)
        ])

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            searchView.alpha = 1
        }
        searchResultsController.endAppearanceTransition()

        searchResultsController.searchShown()
    }

    func searchDidEnd() {
        guard let searchView = searchResultsController.view else { return }

        searchResultsController.beginAppearanceTransition(false, animated: false)
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            searchView.alpha = 0
        }) { _ in
            searchView.removeFromSuperview()
            self.searchResultsController.endAppearanceTransition()
            self.resultsControllerDelegate.clearSearch()
        }

        searchResultsController.searchDismissed()
    }

    func searchWasCleared() {
        resultsControllerDelegate.clearSearch()
    }

    func searchTermChanged(_ searchTerm: String) {}

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        resultsControllerDelegate.performSearch(searchTerm: searchTerm, triggeredByTimer: triggeredByTimer, completion: completion)
    }
}

extension DiscoverCollectionViewController {
    @objc private func chartRegionDidChange() {
        reloadData { [weak self] in
            guard let self else { return }
            if let item = dataSource.snapshot().itemIdentifiers.last,
               let lastIndexPath = dataSource.indexPath(for: item) {
                collectionView.scrollToItem(at: lastIndexPath, at: .top, animated: true)
            }
        }
    }

    @objc private func checkForScrollTap(_ notification: Notification) {
        guard let index = notification.object as? Int, index == tabBarItem.tag else { return }

        let defaultOffset = -PCSearchBarController.defaultHeight - view.safeAreaInsets.top
        if collectionView.contentOffset.y.rounded(.down) > defaultOffset.rounded(.down) {
            collectionView.setContentOffset(CGPoint(x: 0, y: defaultOffset), animated: true)
        } else {
            // When double-tapping on tab bar, dismiss the search if already active
            // else give focus to the search field
            if searchController.cancelButtonShowing {
                searchController.cancelTapped(self)
            } else {
                searchController.searchTextField.becomeFirstResponder()
            }
        }
    }

    @objc private func searchRequested() {
        collectionView.setContentOffset(CGPoint(x: 0, y: -PCSearchBarController.defaultHeight - view.safeAreaInsets.top), animated: false)
        searchController.searchTextField.becomeFirstResponder()
    }
}
