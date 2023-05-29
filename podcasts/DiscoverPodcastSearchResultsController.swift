import PocketCastsDataModel
import PocketCastsServer
import UIKit

class DiscoverPodcastSearchResultsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SearchResultsDelegate {
    private static let searchCellId = "PodcastSearchCell"
    private static let searchInfoCell = "SearchInfoCell"
    private static let searchingCell = "SearchLoadingCell"

    weak var delegate: DiscoverDelegate?
    var searchTextField: UITextField?

    private var searchResults = [PodcastInfo]()

    private enum SearchingState {
        case notStarted, searching, failed, noResults, resultsAvailable
    }

    private var searchState: SearchingState = .notStarted

    @IBOutlet var searchResultsTable: UITableView! {
        didSet {
            searchResultsTable.register(UINib(nibName: "PodcastSearchCell", bundle: nil), forCellReuseIdentifier: DiscoverPodcastSearchResultsController.searchCellId)
            searchResultsTable.register(UINib(nibName: "SearchInfoCell", bundle: nil), forCellReuseIdentifier: DiscoverPodcastSearchResultsController.searchInfoCell)
            searchResultsTable.register(UINib(nibName: "SearchLoadingCell", bundle: nil), forCellReuseIdentifier: DiscoverPodcastSearchResultsController.searchingCell)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // this table now goes under the tab bar, so it has to be inset by it's height to make up for that
        let tabBarHeight = (view.window?.rootViewController as? MainTabBarController)?.tabBar.bounds.height ?? 49
        searchResultsTable.applyInsetForMiniPlayer(additionalBottomInset: tabBarHeight)
    }

    // MARK: - UITableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchState {
        case .notStarted:
            return 0
        case .failed, .searching, .noResults:
            return 1
        case .resultsAvailable:
            return searchResults.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch searchState {
        case .notStarted:
            return tableView.dequeueReusableCell(withIdentifier: DiscoverPodcastSearchResultsController.searchCellId, for: indexPath)
        case .searching:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverPodcastSearchResultsController.searchingCell, for: indexPath) as! SearchLoadingCell
            cell.loadingIndicator.startAnimating()

            return cell
        case .failed:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverPodcastSearchResultsController.searchInfoCell, for: indexPath) as! SearchInfoCell
            cell.showFailed()

            return cell
        case .noResults:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverPodcastSearchResultsController.searchInfoCell, for: indexPath) as! SearchInfoCell
            cell.showNoResults()

            return cell
        case .resultsAvailable:
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverPodcastSearchResultsController.searchCellId, for: indexPath) as! PodcastSearchCell

            let podcastHeader = searchResults[indexPath.row]
            if let uuid = podcastHeader.uuid {
                cell.podcastImage.setPodcast(uuid: uuid, size: .list)
            } else {
                cell.podcastImage.clearArtwork()
            }
            cell.podcastName.text = podcastHeader.title
            cell.podcastAuthor.text = podcastHeader.author
            if let uuid = podcastHeader.uuid, let _ = DataManager.sharedManager.findPodcast(uuid: uuid) {
                cell.subscribedIcon.isHidden = false
            } else {
                cell.subscribedIcon.isHidden = true
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if searchState != .resultsAvailable { return }

        let podcastHeader = searchResults[indexPath.row]
        delegate?.show(podcastInfo: podcastHeader, placeholderImage: nil, isFeatured: false, listUuid: nil)

        Analytics.track(.searchResultTapped, properties: ["uuid": podcastHeader, "result_type": "podcast_remote_result", "source": "discover"])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch searchState {
        case .searching:
            return 100
        case .failed, .noResults:
            return 200
        case .resultsAvailable, .notStarted:
            return 68
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch searchState {
        case .searching:
            return 100
        case .failed, .noResults:
            return 200
        case .resultsAvailable, .notStarted:
            return 68
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let searchField = searchTextField else { return }

        // dismiss the keyboard on scroll down of the results
        if scrollView.contentOffset.y > 40, searchField.isFirstResponder {
            searchField.resignFirstResponder()
        }
    }

    // MARK: - Search

    func clearSearch() {
        searchResults.removeAll()
        searchState = .notStarted
        searchResultsTable.reloadData()
    }

    func performLocalSearch(searchTerm: String) {}

    func performSearch(searchTerm: String, triggeredByTimer: Bool, completion: @escaping (() -> Void)) {
        if !triggeredByTimer, searchTerm.count < 2 {
            completion()

            let alert = UIAlertController(title: L10n.discoverSearchErrorTitle, message: L10n.discoverSearchErrorMsg, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: L10n.ok, style: UIAlertAction.Style.cancel, handler: nil))
            present(alert, animated: true, completion: nil)

            return
        }

        Analytics.track(.searchPerformed, properties: ["source": "discover"])

        let finalSearch = searchTerm.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).stringByRemovingEmoji()

        searchState = .searching
        searchResultsTable.reloadData()
        MainServerHandler.shared.podcastSearch(searchTerm: finalSearch) { [weak self] response in
            guard let response = response, response.success() else {
                self?.searchState = .failed
                DispatchQueue.main.async {
                    Analytics.track(.searchFailed)
                    self?.searchResultsTable.reloadData()
                    completion()
                }

                return
            }

            var updatedResults = [PodcastInfo]()
            if let podcast = response.result?.podcast {
                updatedResults.append(podcast)
            }

            if let podcasts = response.result?.searchResults {
                for podcast in podcasts {
                    updatedResults.append(podcast)
                }
            }

            DispatchQueue.main.async {
                self?.searchState = updatedResults.count == 0 ? .noResults : .resultsAvailable
                self?.searchResults = updatedResults

                self?.searchResultsTable.reloadData()

                completion()
            }
        }
    }
}
