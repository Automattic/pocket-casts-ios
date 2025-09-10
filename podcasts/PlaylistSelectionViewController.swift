import PocketCastsDataModel
import UIKit

class PlaylistSelectionViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private static let filterAutoDownloadCell = "FilterDownloadCell"

    var allPlaylists = [EpisodeFilter]()
    var selectedPlaylists = [String]()
    var playlistSelected: ((EpisodeFilter) -> Void)?
    var playlistUnselected: ((EpisodeFilter) -> Void)?

    private var didChange = false
    var didChangeFilters: (() -> Void)?

    @IBOutlet var playlistSelectionTable: UITableView! {
        didSet {
            playlistSelectionTable.register(UINib(nibName: "FilterDownloadCell", bundle: nil), forCellReuseIdentifier: PlaylistSelectionViewController.filterAutoDownloadCell)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playlistSelectionTable.reloadData()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: playlistSelectionTable)
        title = L10n.settingsSelectFiltersPlural
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didChange {
            didChangeFilters?()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allPlaylists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistSelectionViewController.filterAutoDownloadCell, for: indexPath) as! FilterDownloadCell

        let filter = allPlaylists[indexPath.row]
        cell.populateFrom(filter: filter, selected: selectedPlaylists.contains(filter.uuid))
        cell.filterSwitchToggled = { [weak self] selected in
            guard let self = self else { return }

            if selected {
                self.selectedPlaylists.append(filter.uuid)
                self.playlistSelected?(filter)
            } else {
                self.selectedPlaylists.removeAll { $0 == filter.uuid }
                self.playlistUnselected?(filter)
            }

            self.didChange = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // remove the standard padding from the top of a grouped UITableView
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }
}
