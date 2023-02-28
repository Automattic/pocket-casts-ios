import PocketCastsDataModel
import PocketCastsServer
import UIKit

class PodcastListSearchResultsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SearchResultsDelegate {

    private static let searchCellId = "SearchCell"

    private var localResults = [HomeGridItem]()
    private var remoteResults = [PodcastInfo]()

    private let localSection = 0
    private let remoteSection = 1

    var searchTextField: UITextField?

    @IBOutlet var searchResultsTable: UITableView! {
        didSet {
            searchResultsTable.register(UINib(nibName: "PodcastSearchCell", bundle: nil), forCellReuseIdentifier: PodcastListSearchResultsController.searchCellId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // this table now goes under the tab bar, so it has to be inset by it's height to make up for that
        let tabBarHeight = (view.window?.rootViewController as? MainTabBarController)?.tabBar.bounds.height ?? 49
        searchResultsTable.applyInsetForMiniPlayer(additionalBottomInset: tabBarHeight)
    }

    // MARK: - UITableView methods

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == localSection ? localResults.count : remoteResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PodcastListSearchResultsController.searchCellId, for: indexPath) as! PodcastSearchCell

        if indexPath.section == localSection {
            let item = localResults[indexPath.row]
            if let podcast = item.podcast {
                cell.populateFrom(podcast: podcast)
            } else if let folder = item.folder {
                cell.populateFrom(folder: folder)
            }
        } else {
            let podcastHeader = remoteResults[indexPath.row]
            cell.populateForm(podcastInfo: podcastHeader)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == localSection {
            let item = localResults[indexPath.row]
            if let podcast = item.podcast {
                NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
            } else if let folder = item.folder {
                NavigationManager.sharedManager.navigateTo(NavigationManager.folderPageKey, data: [NavigationManager.folderKey: folder])
            }

            let type = (item.podcast != nil) ? "podcast_local_result" : "folder"
            let uuid = item.podcast?.uuid ?? item.folder?.uuid ?? "unknown"

            Analytics.track(.searchResultTapped, properties: ["uuid": uuid, "result_type": type, "source": analyticsSource])
        } else if indexPath.section == remoteSection {
            let podcastHeader = remoteResults[indexPath.row]
            NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcastHeader])

            Analytics.track(.searchResultTapped, properties: ["uuid": podcastHeader, "result_type": "podcast_remote_result", "source": analyticsSource])
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
        localResults.removeAll()
        remoteResults.removeAll()
        searchResultsTable?.reloadData()
    }

    func performLocalSearch(searchTerm: String) {
        let filteredItems = HomeGridDataHelper.gridListItemsForSearchTerm(searchTerm)

        remoteResults.removeAll()
        localResults = filteredItems
        searchResultsTable?.reloadData()
    }

    func performRemoteSearch(searchTerm: String, completion: @escaping (() -> Void)) {
        let finalSearch = searchTerm.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).stringByRemovingEmoji()

        MainServerHandler.shared.podcastSearch(searchTerm: finalSearch) { response in
            DispatchQueue.main.async { [weak self] in
                guard let response = response, response.success() else {
                    completion()

                    return
                }

                var results = [PodcastInfo]()

                if let podcast = response.result?.podcast {
                    results.append(podcast)
                }

                if let podcasts = response.result?.searchResults, let localItems = self?.localResults {
                    for podcastInfo in podcasts {
                        if let uuid = podcastInfo.uuid {
                            if !localItems.contains(where: { item -> Bool in item.podcast?.uuid == uuid }) {
                                results.append(podcastInfo)
                            }
                        }
                    }
                }

                completion()
                self?.remoteResults = results
                self?.searchResultsTable?.reloadData()
            }
        }
    }
}

extension PodcastListSearchResultsController: AnalyticsSourceProvider {
    var analyticsSource: AnalyticsSource {
        .podcastsList
    }
}
