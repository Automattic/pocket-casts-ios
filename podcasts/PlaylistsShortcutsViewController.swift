import IntentsUI
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class PlaylistsShortcutsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private var tableView: UITableView! {
        didSet {
            registerCells()

            tableView.separatorStyle = .none
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = PlaylistCell.cellHeight
            tableView.sectionHeaderHeight = UITableView.automaticDimension
            tableView.estimatedSectionHeaderHeight = Constants.Values.tableSectionHeaderHeight
        }
    }

    var playlists: [EpisodeFilter] = []
    weak var delegate: SiriSettingsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.settingsSelectPlaylistSingular
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = playlists[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.reuseIdentifier, for: indexPath) as! PlaylistCell
        cell.configure(cellType: .plain, playlist: playlist, isLastRow: indexPath.row == playlists.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let singleFilterVC = PlaylistShortcutsViewController(playlist: playlists[indexPath.row])
        navigationController?.pushViewController(singleFilterVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: false)
    }

    private func registerCells() {
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
    }
}
