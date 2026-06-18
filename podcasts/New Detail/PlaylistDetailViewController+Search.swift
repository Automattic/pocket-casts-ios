import UIKit

extension PlaylistDetailViewController: PCSearchBarDelegate {
    func searchDidBegin() {
        if preSearchContentOffset == nil && !viewModel.isSearching {
            preSearchContentOffset = tableView.contentOffset
        }
        viewModel.startSearch()

        // Pad the bottom so the table has enough room to scroll the artwork header fully off-screen
        // and keep it there even when the search returns few results — otherwise a short list
        // rubber-bands back to the top and the header pops back into view (PCIOS-609). Mirrors
        // PodcastViewController.didActivateSearch(); 335 is the PlaylistHeaderViewCell height.
        let tableBounds = tableView.bounds
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableBounds.width, height: tableBounds.height - 335))
        footer.backgroundColor = .clear
        tableView.tableFooterView = footer

        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 1), at: .top, animated: true)
    }

    func searchDidEnd() {
        viewModel.endSearch()
        tableView.tableFooterView = nil
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
