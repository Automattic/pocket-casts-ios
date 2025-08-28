import UIKit

extension PlaylistDetailViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        viewModel.startSearch()
    }

    func searchDidEnd() {
        viewModel.endSearch()
    }

    func searchWasCleared() {
        Analytics.track(.searchCleared, source: analyticsSource)

        viewModel.clearSearch()
        tableView.reloadData()
    }

    func searchTermChanged(_ searchTerm: String) { }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        Analytics.track(.searchPerformed, source: analyticsSource)
        viewModel.searchEpisodes(for: searchTerm)
        completion()
    }
}
