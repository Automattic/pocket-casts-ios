import UIKit
import PocketCastsDataModel
import PocketCastsUtils

extension PodcastListViewController: UIScrollViewDelegate, PCSearchBarDelegate {
    var searchControllerView: UIView? {
        searchResultsController.view
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
    }

    func showSortOrderOptions() {
        let options = OptionsPicker(title: L10n.sortBy.localizedUppercase)

        let sortOption: LibrarySort
        if !FeatureFlag.podcastsSortChanges.enabled, Settings.homeFolderSortOrder() == .recentlyPlayed {
            Settings.setHomeFolderSortOrder(order: .dateAddedNewestToOldest)
            sortOption = .dateAddedNewestToOldest
        } else {
            sortOption = Settings.homeFolderSortOrder()
        }

        let podcastNameAction = OptionAction(label: LibrarySort.titleAtoZ.description, selected: sortOption == .titleAtoZ) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .titleAtoZ)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.titleAtoZ])
        }

        let releaseDateAction = OptionAction(label: LibrarySort.episodeDateNewestToOldest.description, selected: sortOption == .episodeDateNewestToOldest) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .episodeDateNewestToOldest)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.episodeDateNewestToOldest])
        }

        let subscribedOrder = OptionAction(label: LibrarySort.dateAddedNewestToOldest.description, selected: sortOption == .dateAddedNewestToOldest) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .dateAddedNewestToOldest)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.dateAddedNewestToOldest])
        }

        let dragAndDropAction = OptionAction(label: LibrarySort.custom.description, selected: sortOption == .custom) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .custom)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.custom])
        }

        let recentlyPlayedOrder = OptionAction(label: LibrarySort.recentlyPlayed.description, selected: sortOption == .recentlyPlayed) { [weak self] in
            guard let strongSelf = self else { return }

            Settings.setHomeFolderSortOrder(order: .recentlyPlayed)
            strongSelf.refreshGridItems()
            Analytics.track(.podcastsListSortOrderChanged, properties: ["sort_by": LibrarySort.recentlyPlayed])
        }

        if FeatureFlag.podcastsSortChanges.enabled {
            options.addAction(action: subscribedOrder)
            options.addAction(action: releaseDateAction)
            options.addAction(action: recentlyPlayedOrder)
            options.addAction(action: podcastNameAction)
            options.addAction(action: dragAndDropAction)
        } else {
            options.addAction(action: podcastNameAction)
            options.addAction(action: releaseDateAction)
            options.addAction(action: subscribedOrder)
            options.addAction(action: dragAndDropAction)
        }

        options.show(statusBarStyle: preferredStatusBarStyle)
    }

    // MARK: - PCSearchBarDelegate

    func searchDidBegin() {
        guard let searchView = searchControllerView,
              searchView.superview == nil else {
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

        searchResultsController.searchShown()
    }

    func searchDidEnd() {
        guard let searchView = searchControllerView else {
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            searchView.alpha = 0
        }) { _ in
            searchView.removeFromSuperview()

            self.searchResultsController.clearSearch()
        }

        searchResultsController.searchDismissed()
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
