import UIKit
import SwiftUI
import PocketCastsUtils

extension PlaylistDetailViewController: UITableViewDataSource {
    private static let cellIdentifier = "EpisodeCell"

    func registerCells() {
        tableView.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: Self.cellIdentifier)
        tableView.register(EmptyStateCell.self, forCellReuseIdentifier: EmptyStateCell.reuseIdentifier)
        tableView.register(DummyEmptyCell.self, forCellReuseIdentifier: DummyEmptyCell.reuseIdentifier)
        tableView.register(PlaylistHeaderViewCell.self, forCellReuseIdentifier: PlaylistHeaderViewCell.reuseIdentifier)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            guard let indexPath = tableView.indexPathForRow(at: touchPoint), indexPath.section == 1 else { return }
            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    Analytics.track(.filterSelectAllAbove)
                    self.tableView.selectAllAbove(indexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    Analytics.track(.filterSelectAllBelow)
                    self.tableView.selectAllBelow(indexPath: indexPath)
                })
                optionPicker.addAction(action: allAboveAction)
                optionPicker.addAction(action: allBelowAction)
                optionPicker.show(statusBarStyle: preferredStatusBarStyle)
            } else {
                longPressMultiSelectIndexPath = indexPath
                isMultiSelectEnabled = true
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dataSource[safe: section]?.elements.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistHeaderViewCell.reuseIdentifier, for: indexPath) as! PlaylistHeaderViewCell
            cell.configure(viewModel: viewModel)
            return cell
        }

        guard let itemAtRow = viewModel.dataSource[safe: indexPath.section]?.elements[safe: indexPath.row] as? ListItem else {
            FileLog.shared.addMessage("Playlist Detail tableView: missing ListItem in section \(indexPath.section), row \(indexPath.row)")
            return UITableViewCell()
        }

        if itemAtRow is NoSearchResultsPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
            cell.configure(
                title: L10n.discoverNoEpisodesFound,
                message: L10n.discoverNoPodcastsFoundMsg) {
                    Image("empty-playlist-info")
                }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as! EpisodeCell

        cell.playlist = .filter(uuid: viewModel.playlist.uuid)
        cell.delegate = self
        if let listEpisode = itemAtRow as? ListEpisode {
            cell.populateFrom(episode: listEpisode.episode, tintColor: viewModel.playlist.playlistColor(), playlistUuid: viewModel.playlist.uuid)
            cell.shouldShowSelect = isMultiSelectEnabled
            if isMultiSelectEnabled {
                cell.showTick = selectedEpisodesContains(uuid: listEpisode.episode.uuid)
            }
        }
        return cell
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 1 ? searchHeaderView : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? PCSearchBarController.defaultHeight : 0
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section != 1 { return nil }
        guard tableView.isEditing, !multiSelectGestureInProgress else { return indexPath }
        if let selectedEpisode = viewModel.episodes[safe: indexPath.row], selectedEpisodes.contains(selectedEpisode) {
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 1 { return }
        guard let selectedEpisode = viewModel.episodes[safe: indexPath.row]?.episode, let parentPodcast = selectedEpisode.parentPodcast() else { return }

        if isMultiSelectEnabled {
            let listEpisode = viewModel.episodes[indexPath.row]

            if !multiSelectGestureInProgress {
                // If the episode is already selected move to the end of the array
                selectedEpisodesRemove(uuid: listEpisode.episode.uuid)
            }

            if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: listEpisode.episode.uuid) {
                selectedEpisodes.append(listEpisode)
                // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell? {
                    cell?.showTick = true
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            let episodeController = EpisodeDetailViewController(episode: selectedEpisode, podcast: parentPodcast, source: .filters, playlist: .filter(uuid: viewModel.playlist.uuid))
            episodeController.modalPresentationStyle = .formSheet
            present(episodeController, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section != 1 { return }
        guard isMultiSelectEnabled else { return }
        if let listEpisode = viewModel.episodes[safe: indexPath.row], let index = selectedEpisodes.firstIndex(of: listEpisode) {
            selectedEpisodes.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell {
                cell.showTick = false
            }
        }
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        if indexPath.section != 1 { return false }
        return Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if indexPath.section != 1 { return }
        isMultiSelectEnabled = true
        multiSelectGestureInProgress = true
    }

    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        multiSelectGestureInProgress = false
    }
}

fileprivate class DummyEmptyCell: ThemeableCell {
    static let reuseIdentifier = "DummyEmptyCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    override func setEditing(_ editing: Bool, animated: Bool) {}
}
