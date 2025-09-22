import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import SwiftUI

class PlaylistSelectionViewController: PCViewController, UITableViewDelegate, UITableViewDataSource {
    private static let playlistAutoDownloadCell = "PlaylistAutoDownloadCell"

    var allPlaylists = [EpisodeFilter]()
    var selectedPlaylists = [String]()
    var playlistSelected: ((EpisodeFilter) -> Void)?
    var playlistUnselected: ((EpisodeFilter) -> Void)?

    private var didChange = false
    var didChangePlaylist: (() -> Void)?

    var navigationTitle: String = L10n.settingsSelectFiltersPlural {
        didSet {
            title = navigationTitle
        }
    }

    @IBOutlet var playlistSelectionTable: UITableView! {
        didSet {
            if FeatureFlag.playlistsRebranding.enabled {
                playlistSelectionTable.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
            } else {
                playlistSelectionTable.register(UINib(nibName: "FilterDownloadCell", bundle: nil), forCellReuseIdentifier: PlaylistSelectionViewController.playlistAutoDownloadCell)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playlistSelectionTable.reloadData()
        insetAdjuster.setupInsetAdjustmentsForMiniPlayer(scrollView: playlistSelectionTable)

        if !FeatureFlag.playlistsRebranding.enabled {
            title = L10n.settingsSelectFiltersPlural
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if didChange {
            didChangePlaylist?()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allPlaylists.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FeatureFlag.playlistsRebranding.enabled ? PlaylistCell.cellHeight : 62.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let playlist = allPlaylists[indexPath.row]
        let onToggleChange: (Bool) -> Void = { [weak self] selected in
            guard let self = self else { return }

            if selected {
                self.selectedPlaylists.append(playlist.uuid)
                self.playlistSelected?(playlist)
            } else {
                self.selectedPlaylists.removeAll { $0 == playlist.uuid }
                self.playlistUnselected?(playlist)
            }

            self.didChange = true
        }

        if FeatureFlag.playlistsRebranding.enabled {
            let isSelected = Binding<Bool>(
                get: { [weak self] in
                    guard let self = self else { return false }
                    return self.selectedPlaylists.contains(playlist.uuid)
                },
                set: { newValue in
                    onToggleChange(newValue)
                }
            )

            let isLastRow = indexPath.row == allPlaylists.count - 1
            let cell = cell(tableView, for: PlaylistCell.reuseIdentifier) as! PlaylistCell
            cell.configure(cellType: .toggle, playlist: playlist, isLastRow: isLastRow, isSelected: isSelected)
            return cell
        }

        let selected = selectedPlaylists.contains(playlist.uuid)
        let cell = cell(tableView, for: PlaylistSelectionViewController.playlistAutoDownloadCell) as! FilterDownloadCell
        cell.populateFrom(filter: playlist, selected: selected)
        cell.filterSwitchToggled = onToggleChange
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // remove the standard padding from the top of a grouped UITableView
        section == 0 ? CGFloat.leastNonzeroMagnitude : 19
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }

    private func cell(_ tableView: UITableView, for identifier: String) -> ThemeableCell? {
        if FeatureFlag.playlistsRebranding.enabled {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? PlaylistCell {
                return cell
            }
            return PlaylistCell(style: .default, reuseIdentifier: identifier)
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FilterDownloadCell {
                return cell
            }
            let nib = UINib(nibName: "FilterDownloadCell", bundle: nil)
            let objects = nib.instantiate(withOwner: nil, options: nil)
            if let cell = objects.first as? FilterDownloadCell {
                return cell
            }
        }
        return nil
    }
}
