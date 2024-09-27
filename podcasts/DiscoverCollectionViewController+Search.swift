// All code needed for hooking up the search bar and related functionality to DiscoverCollectionViewController

extension DiscoverCollectionViewController {
    func setupSearchBar() {
        collectionView.delegate = self // For the UIScrollViewDelegate callbacks

        addCustomObserver(Constants.Notifications.chartRegionChanged, selector: #selector(chartRegionDidChange))
        addCustomObserver(Constants.Notifications.tappedOnSelectedTab, selector: #selector(checkForScrollTap(_:)))

        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.didMove(toParent: self)

        let topAnchor = searchController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -PCSearchBarController.defaultHeight)
        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor
        ])
        searchController.searchControllerTopConstant = topAnchor

        searchController.setupScrollView(collectionView, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self
    }
}

extension DiscoverCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchResultsController.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
    }
}

extension DiscoverCollectionViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        guard let searchView = searchResultsController.view, searchView.superview == nil else {
            return
        }

        searchView.alpha = 0
        addChild(searchResultsController)
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
    }

    func searchDidEnd() {
        guard let searchView = searchResultsController.view else { return }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            searchView.alpha = 0
        }) { _ in
            searchView.removeFromSuperview()
            self.resultsControllerDelegate.clearSearch()
        }

        Analytics.track(.searchDismissed, properties: ["source": AnalyticsSource.discover])
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
        reloadData()
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
