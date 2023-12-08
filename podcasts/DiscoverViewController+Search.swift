import Foundation

extension DiscoverViewController: PCSearchBarDelegate, UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard newSearchResultsController.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard newSearchResultsController.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
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

        searchController.setupScrollView(mainScrollView, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self
    }

    func searchDidBegin() {
        guard let searchView = newSearchResultsController.view, searchView.superview == nil else {
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
        guard let searchView = newSearchResultsController.view else { return }

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
