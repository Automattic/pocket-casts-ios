import UIKit

extension PodcastListViewController: UIScrollViewDelegate, PCSearchBarDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchResultsControler?.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
        refreshControl?.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard searchResultsControler?.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        refreshControl?.scrollViewDidEndDragging(scrollView)
    }

    func setupSearchBar() {
        searchController = PCSearchBarController()
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchController.view)

        let topAnchor = searchController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -PCSearchBarController.defaultHeight)
        NSLayoutConstraint.activate([
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.heightAnchor.constraint(equalToConstant: PCSearchBarController.defaultHeight),
            topAnchor
        ])
        searchController.searchControllerTopConstant = topAnchor

        searchController.setupScrollView(podcastsCollectionView, hideSearchInitially: !UIAccessibility.isVoiceOverRunning)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self

        searchResultsControler = PodcastListSearchResultsController()
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
        guard let searchView = searchResultsControler.view else { return }

        searchView.alpha = 0
        view.addSubview(searchView)

        searchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            searchView.topAnchor.constraint(equalTo: searchController.view.bottomAnchor)
        ])

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            self.searchResultsControler.view.alpha = 1
        }
    }

    func searchDidEnd() {
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            self.searchResultsControler.view.alpha = 0
        }) { _ in
            self.searchResultsControler.view.removeFromSuperview()
            self.searchResultsControler.clearSearch()
        }
    }

    func searchWasCleared() {
        searchResultsControler.clearSearch()
    }

    func searchTermChanged(_ searchTerm: String) {
        searchResultsControler.performLocalSearch(searchTerm: searchTerm)

        debounce.call {
            if !searchTerm.trim().isEmpty {
                Analytics.track(.searchPerformed, properties: ["source": "podcasts_list"])
            }
        }
    }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        searchResultsControler.performRemoteSearch(searchTerm: searchTerm, completion: completion)
    }
}
