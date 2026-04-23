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
        tableView.register(PlaylistArchiveViewCell.self, forCellReuseIdentifier: PlaylistArchiveViewCell.reuseIdentifier)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            let section = viewModel.index(for: .episodes)
            guard let indexPath = tableView.indexPathForRow(at: touchPoint),
                  indexPath.section == section,
                  let episode = viewModel.episodes[safe: indexPath.row]?.episode,
                  episode.wasDeleted == false else { return }
            if isMultiSelectEnabled {
                longPressSelectOptions(
                    for: indexPath,
                    in: tableView,
                    statusBarStyle: preferredStatusBarStyle
                ) { [weak self] allAboveAreSelected in
                    self?.track(allAboveAreSelected ? .filterDeselectAllAbove : .filterSelectAllAbove)
                } allBelowAction: { [weak self] allBelowAreSelected in
                    self?.track(allBelowAreSelected ? .filterDeselectAllBelow : .filterSelectAllBelow)
                }
            } else {
                longPressMultiSelectIndexPath = indexPath
                isMultiSelectEnabled = true
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.dataSource[safe: section]?.elements.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == viewModel.index(for: .header) {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistHeaderViewCell.reuseIdentifier, for: indexPath) as! PlaylistHeaderViewCell
            cell.configure(viewModel: viewModel)
            return cell
        }

        guard let itemAtRow = viewModel.dataSource[safe: indexPath.section]?.elements[safe: indexPath.row] as? ListItem else {
            FileLog.shared.addMessage("Playlist Detail tableView: missing ListItem in section \(indexPath.section), row \(indexPath.row)")
            return UITableViewCell()
        }

        let onToggleChange: (Bool) -> Void = { [weak self] selected in
            guard let self = self else { return }

            self.track(selected ? .filterShowArchivedTapped : .filterHideArchivedTapped)
            self.viewModel.updateShowArchivedEpisodes(show: selected)
            self.viewModel.reloadEpisodeList(animated: true)
        }

        if let placeholder = itemAtRow as? PlaylistArchiveViewCellPlaceholder,
           viewModel.isManualPlaylist,
           indexPath.section == viewModel.index(for: .archive) {
            if viewModel.archivedEpisodesCount == 0 {
                return tableView.dequeueReusableCell(withIdentifier: DummyEmptyCell.reuseIdentifier, for: indexPath) as! DummyEmptyCell
            }
            let isSelected = Binding<Bool>(
                get: { [weak self] in
                    guard let self = self else { return false }
                    return self.viewModel.shouldShowArchived
                },
                set: { newValue in
                    onToggleChange(newValue)
                }
            )
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistArchiveViewCell.reuseIdentifier, for: indexPath) as! PlaylistArchiveViewCell
            cell.configure(archivedEpisodesCount: placeholder.archived, isSelected: isSelected)
            return cell
        }

        if itemAtRow is NoSearchResultsPlaceholder {
            return configuredEmptyCell(
                for: tableView,
                at: indexPath,
                title: L10n.discoverNoEpisodesFound,
                message: L10n.discoverNoPodcastsFoundMsg
            )
        } else if let archivedPlaceholder = itemAtRow as? AllArchivedPlaceholder {
            return configuredEmptyCell(
                for: tableView,
                at: indexPath,
                title: FeatureFlag.playlistsRebranding.enabled ?  L10n.episodeFilterNoEpisodesTitle.sentenceCased : L10n.episodeFilterNoEpisodesTitle,
                message: archivedPlaceholder.message,
                actions: [
                    .init(title: FeatureFlag.playlistsRebranding.enabled ? L10n.podcastShowArchived.sentenceCased : L10n.podcastShowArchived, action: { [weak self] in
                        self?.track(.filterShowArchivedCtaEmptyTapped)
                        onToggleChange(true)
                    })
                ]
            )
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as! EpisodeCell
        cell.episodeImageLeadConstraint.constant = 16.0
        cell.playlist = .filter(uuid: viewModel.playlist.uuid)
        cell.delegate = self
        if let listEpisode = itemAtRow as? ListEpisode {
            cell.populateFrom(episode: listEpisode.episode, tintColor: nil, playlistUuid: viewModel.playlist.uuid)
            cell.shouldShowSelect = isMultiSelectEnabled
            if isMultiSelectEnabled {
                cell.showTick = selectedEpisodesContains(uuid: listEpisode.episode.uuid)
            }
        }
        return cell
    }

    private func configuredEmptyCell(
        for tableView: UITableView,
        at indexPath: IndexPath,
        title: String,
        message: String,
        actions: [EmptyStateAction] = []
    ) -> EmptyStateCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: EmptyStateCell.reuseIdentifier,
            for: indexPath
        ) as! EmptyStateCell
        cell.configure(
            title: title,
            message: message,
            icon: {
                Image(systemName: "info.circle")
            },
            actions: actions)
        return cell
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.isManualPlaylist, indexPath.section == viewModel.index(for: .archive) {
            return viewModel.archivedEpisodesCount == 0 ? 1 : 49.0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let searchSection: PlaylistDetailViewModel.Section = viewModel.isManualPlaylist ? .archive : .episodes
        return section == viewModel.index(for: searchSection) ? searchHeaderView : nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let searchSection: PlaylistDetailViewModel.Section = viewModel.isManualPlaylist ? .archive : .episodes
        return section == viewModel.index(for: searchSection) ? PCSearchBarController.defaultHeight : 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == viewModel.index(for: .episodes)
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section != viewModel.index(for: .episodes) { return nil }
        if tableView.isEditing,
           let episode = viewModel.episodes[safe: indexPath.row]?.episode,
           episode.wasDeleted {
            return nil
        }
        guard tableView.isEditing, !multiSelectGestureInProgress else { return indexPath }
        if let selectedEpisode = viewModel.episodes[safe: indexPath.row], selectedEpisodes.contains(selectedEpisode) {
            tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != viewModel.index(for: .episodes) { return }
        guard let selectedEpisode = viewModel.episodes[safe: indexPath.row]?.episode, let parentPodcast = selectedEpisode.parentPodcast() else { return }

        if isMultiSelectEnabled {
            let listEpisode = viewModel.episodes[indexPath.row]
            if listEpisode.episode.wasDeleted {
                return
            }

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

            if selectedEpisode.wasDeleted {
                let episodeUuid = selectedEpisode.uuid
                let view = ModalMessageViewController.episodeUnavailableAlert { [weak self] in
                    guard let self else { return }
                    self.track(.filterRemoveFromPlaylistTapped)
                    self.track(episode: selectedEpisode, added: false, to: self.viewModel.playlist, source: "unavailable_episode")
                    self.viewModel.remove(episode: episodeUuid, at: indexPath.row)
                }
                BottomSheetSwiftUIWrapper.present(
                    view.environmentObject(Theme.sharedTheme),
                    autoSize: true,
                    showingGrabber: true,
                    in: self
                )
                return
            }

            let episodeController = EpisodeDetailViewController(episode: selectedEpisode, podcast: parentPodcast, source: .filters, playlist: .filter(uuid: viewModel.playlist.uuid))
            episodeController.modalPresentationStyle = .formSheet
            present(episodeController, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section != viewModel.index(for: .episodes) { return }
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
        if indexPath.section != viewModel.index(for: .episodes) { return false }
        if let episode = viewModel.episodes[safe: indexPath.row]?.episode, episode.wasDeleted {
            return false
        }
        return Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if indexPath.section != viewModel.index(for: .episodes) { return }
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
