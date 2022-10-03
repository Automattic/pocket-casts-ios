import Foundation

extension DiscoverViewController: PCSearchBarDelegate, UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard searchResultsController?.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard searchResultsController?.view?.superview == nil else { return } // don't send scroll events while the search results are up

        searchController.parentScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
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

        searchController.setupScrollView(mainScrollView, hideSearchInitially: false)
        searchController.searchDebounce = Settings.podcastSearchDebounceTime()
        searchController.searchDelegate = self

        searchResultsController = DiscoverPodcastSearchResultsController()
        searchResultsController.delegate = self
        searchResultsController.searchTextField = searchController.searchTextField
    }

    func searchDidBegin() {
        guard let searchView = searchResultsController.view else { return }

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
            self.searchResultsController.view.alpha = 1
        }
    }

    func searchDidEnd() {
        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: {
            self.searchResultsController.view.alpha = 0
        }) { _ in
            self.searchResultsController.view.removeFromSuperview()
            self.searchResultsController.clearSearchResults()
        }
    }

    func searchWasCleared() {
        searchResultsController.clearSearchResults()
    }

    func searchTermChanged(_ searchTerm: String) {}

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        searchResultsController.performSearch(searchTerm: searchTerm, triggeredByTimer: triggeredByTimer, completion: completion)
    }
}
