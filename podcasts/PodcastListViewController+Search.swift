import UIKit

extension PodcastListViewController: UIScrollViewDelegate, PCSearchBarDelegate {
    var searchControllerView: UIView? {
        newSearchResultsController.view
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchControllerView?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
        refreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard searchControllerView?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        refreshControl?.scrollViewDidEndDragging(scrollView)
    }

    func setupSearchBar() {
        searchController = PCSearchBarController()
        searchResultsControler = PodcastListSearchResultsController()

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

        searchController.setupScrollView(podcastsCollectionView, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self

        searchResultsControler.searchTextField = searchController.searchTextField
    }

    func showSortOrderOptions() {
        let options = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        let sortOption = Settings.homeFolderSortOrder()

        let podcastNameAction = OptionAction(label: LibrarySort.titleAtoZ.description, selected: sortOption == .titleAtoZ) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .titleAtoZ)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.titleAtoZ])
        }
        options.addAction(action: podcastNameAction)

        let releaseDateAction = OptionAction(label: LibrarySort.episodeDateNewestToOldest.description, selected: sortOption == .episodeDateNewestToOldest) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .episodeDateNewestToOldest)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.episodeDateNewestToOldest])
        }
        options.addAction(action: releaseDateAction)

        let subscribedOrder = OptionAction(label: LibrarySort.dateAddedNewestToOldest.description, selected: sortOption == .dateAddedNewestToOldest) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .dateAddedNewestToOldest)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.dateAddedNewestToOldest])
        }
        options.addAction(action: subscribedOrder)

        let dragAndDropAction = OptionAction(label: LibrarySort.custom.description, selected: sortOption == .custom) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .custom)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.custom])
        }
        options.addAction(action: dragAndDropAction)

        options.show(statusBarStyle: preferredStatusBarStyle)
    }

    // MARK: - PCSearchBarDelegate

    func searchDidBegin() {
        guard let searchView = searchControllerView,
              searchView.superview == nil else {
            return
        }

        searchView.alpha = 0
        addChild(newSearchResultsController)
        view.addSubview(searchView)
        newSearchResultsController.didMove(toParent: self)


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
        guard let searchView = searchControllerView else {
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            searchView.alpha = 0
        }) { _ in
            searchView.removeFromSuperview()

            self.newSearchResultsController.clearSearch()
        }

        Analytics.track(.searchDismissed, properties: ["source": AnalyticsSource.podcastsList])
    }

    func searchWasCleared() {
        resultsControllerDelegate.clearSearch()
    }

    func searchTermChanged(_ searchTerm: String) {
        resultsControllerDelegate.performLocalSearch(searchTerm: searchTerm)
    }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        resultsControllerDelegate.performSearch(searchTerm: searchTerm, triggeredByTimer: triggeredByTimer, completion: completion)
    }
}
