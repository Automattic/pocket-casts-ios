import UIKit

extension PlaylistDetailViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        viewModel.isSearching = true
        tempEpisodes = viewModel.episodes
    }

    func searchDidEnd() {
        viewModel.isSearching = false
        viewModel.update(episodes: tempEpisodes)
        refreshFilterFromNotification()
    }

    func searchWasCleared() {
        Analytics.track(.searchCleared, source: analyticsSource)

        searchDidEnd()
    }

    func searchTermChanged(_ searchTerm: String) { }

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        Analytics.track(.searchPerformed, source: analyticsSource)
        viewModel.searchEpisodes(for: searchTerm)
        completion()
    }
}
