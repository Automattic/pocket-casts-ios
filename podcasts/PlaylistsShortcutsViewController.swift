import IntentsUI
import PocketCastsDataModel
import PocketCastsUtils
import UIKit

class PlaylistsShortcutsViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private let addCellId = "siriAddCellId"
    private let playlistsRebrandingEnabled = FeatureFlag.playlistsRebranding.enabled

    @IBOutlet private var tableView: UITableView! {
        didSet {
            registerCells()

            if playlistsRebrandingEnabled {
                tableView.separatorStyle = .none
            }
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = playlistsRebrandingEnabled ? PlaylistCell.cellHeight : Constants.Values.tableRowHeaderHeight
            tableView.sectionHeaderHeight = UITableView.automaticDimension
            tableView.estimatedSectionHeaderHeight = Constants.Values.tableSectionHeaderHeight
        }
    }

    var playlists: [EpisodeFilter] = []
    weak var delegate: SiriSettingsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = playlistsRebrandingEnabled ? L10n.settingsSelectPlaylistSingular : L10n.settingsSelectFilterSingular
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = playlists[indexPath.row]

        if playlistsRebrandingEnabled {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.reuseIdentifier, for: indexPath) as! PlaylistCell
            cell.configure(cellType: .plain, playlist: playlist, isLastRow: indexPath.row == playlists.count - 1)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: addCellId) as! SiriShortcutAddCell
        cell.populateFrom(filter: playlist)
        cell.addIcon.isHidden = true
        cell.accessoryType = .disclosureIndicator
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
        if playlistsRebrandingEnabled {
            tableView.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
        } else {
            tableView.register(UINib(nibName: "SiriShortcutAddCell", bundle: nil), forCellReuseIdentifier: addCellId)
        }
    }
}
