import UIKit
import SwiftUI

extension PlaylistPreviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if viewModel.isInPreview {
            return viewModel.episodes.isEmpty ? 1 : viewModel.episodes.count
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: SmartPlaylistRulesCell.reuseIdentifier) as! SmartPlaylistRulesCell
            cell.configure(with: viewModel)
            return cell
        }
        if viewModel.episodes.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: Cells.emptyEpisodesCellId)!
            cell.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentView.backgroundColor = AppTheme.colorForStyle(.primaryUi01)
            cell.contentConfiguration = ContentUnavailableConfiguration.emptyState(
                title: L10n.filterCreateNoEpisodes,
                message: L10n.playlistCreateNoEpisodesDescription,
                icon: {
                    Image("empty-playlist-info")
                })
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Cells.episodeCellId, for: indexPath) as! EpisodePreviewCell
        cell.style = .primaryUi01
        if let listEpisode = viewModel.episodes[safe: indexPath.row] {
            cell.populateFrom(episode: listEpisode.episode)
        }
        return cell
    }
}

extension PlaylistPreviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
