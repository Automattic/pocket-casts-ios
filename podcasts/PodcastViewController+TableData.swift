import PocketCastsDataModel
import UIKit

extension PodcastViewController: UITableViewDataSource, UITableViewDelegate {
    private static let episodeCellId = "EpisodeCell"
    private static let headerCellId = "HeaderCell"
    private static let limitCellId = "LimitCell"
    private static let noSearchResultsCell = "NoSearchResults"
    private static let allArchivedCellId = "AllArchivedCell"
    private static let groupHeadingCellId = "GroupHeading"

    func registerCells() {
        episodesTable.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.episodeCellId)
        episodesTable.register(UINib(nibName: "PodcastHeadingTableCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.headerCellId)
        episodesTable.register(UINib(nibName: "EpisodeLimitCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.limitCellId)
        episodesTable.register(UINib(nibName: "AllArchivedCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.allArchivedCellId)
        episodesTable.register(UINib(nibName: "HeadingCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.groupHeadingCellId)
        episodesTable.register(UINib(nibName: "NoSearchResultsCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.noSearchResultsCell)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        episodesTable.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: episodesTable)
            guard let indexPath = episodesTable.indexPathForRow(at: touchPoint), episodeAtIndexPath(indexPath) != nil else { return }

            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    self.episodesTable.selectAllFrom(fromIndexPath: IndexPath(row: 0, section: PodcastViewController.allEpisodesSection), toIndexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    self.episodesTable.selectAllBelow(indexPath: indexPath)
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

    // MARK: - Table Data

    func numberOfSections(in tableView: UITableView) -> Int {
        loadingPodcastInfo ? 0 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadingPodcastInfo { return 0 }

        return episodeInfo[safe: section]?.elements.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == PodcastViewController.headerSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.headerCellId, for: indexPath) as! PodcastHeadingTableCell
            cell.populateFrom(tintColor: podcast?.iconTintColor(), delegate: self, parentController: self)
            cell.buttonsEnabled = !isMultiSelectEnabled
            return cell
        }

        let itemAtRow = episodeInfo[indexPath.section].elements[indexPath.row]
        if let listEpisode = itemAtRow as? ListEpisode {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.episodeCellId, for: indexPath) as! EpisodeCell
            cell.hidesArtwork = true

            if let podcast {
                cell.playlist = .podcast(uuid: podcast.uuid)
            }

            cell.delegate = self
            cell.populateFrom(episode: listEpisode.episode, tintColor: podcast?.iconTintColor(), podcastUuid: podcast?.uuid, listUuid: listUuid)
            cell.shouldShowSelect = isMultiSelectEnabled
            if isMultiSelectEnabled {
                cell.showTick = selectedEpisodesContains(uuid: listEpisode.episode.uuid)
            }
            return cell
        } else if let limitPlaceholder = itemAtRow as? EpisodeLimitPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.limitCellId, for: indexPath) as! EpisodeLimitCell
            cell.limitMessage.text = limitPlaceholder.message
            return cell
        } else if itemAtRow is NoSearchResultsPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.noSearchResultsCell, for: indexPath) as! NoSearchResultsCell
            return cell
        } else if let archivedPlaceholder = itemAtRow as? AllArchivedPlaceholder {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.allArchivedCellId, for: indexPath) as! AllArchivedCell
            cell.episodesArchivedLabel.text = archivedPlaceholder.message
            return cell
        } else if let heading = itemAtRow as? ListHeader {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.groupHeadingCellId, for: indexPath) as! HeadingCell
            cell.heading.text = heading.headerTitle
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.limitCellId, for: indexPath) as! EpisodeLimitCell
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? 80
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.section == PodcastViewController.allEpisodesSection, episodeAtIndexPath(indexPath) != nil else { return nil }

        guard episodesTable.isEditing, !multiSelectGestureInProgress else { return indexPath }

        if let selectedEpisode = episodeInfo[indexPath.section].elements[safe: indexPath.row] as? ListEpisode {
            if selectedEpisodes.contains(selectedEpisode) {
                tableView.delegate?.tableView?(tableView, didDeselectRowAt: indexPath)
                return nil
            }
            return indexPath
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMultiSelectEnabled, indexPath.section == PodcastViewController.allEpisodesSection {
            if let listEpisode = episodeInfo[indexPath.section].elements[indexPath.row] as? ListEpisode {
                if !multiSelectGestureInProgress {
                    // If the episode is already selected move to the end of the array
                    selectedEpisodesRemove(uuid: listEpisode.episode.uuid)
                }

                if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: listEpisode.episode.uuid) {
                    selectedEpisodes.append(listEpisode)
                    // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                    if let cell = episodesTable.cellForRow(at: indexPath) as? EpisodeCell? {
                        cell?.showTick = true
                    }
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            if indexPath.section == PodcastViewController.headerSection {
                if let cell = tableView.cellForRow(at: indexPath) as? PodcastHeadingTableCell, !isMultiSelectEnabled {
                    cell.toggleExpanded(delegate: self)
                }
            } else if indexPath.section == PodcastViewController.allEpisodesSection {
                guard let podcast = podcast, let episode = episodeAtIndexPath(indexPath) else { return }

                let episodeController = EpisodeDetailViewController(episode: episode, podcast: podcast, source: .podcastScreen, playlist: .podcast(uuid: podcast.uuid))
                episodeController.modalPresentationStyle = .formSheet
                present(episodeController, animated: true, completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isMultiSelectEnabled else { return }
        if let listEpisode = episodeInfo[indexPath.section].elements[indexPath.row] as? ListEpisode, let index = selectedEpisodes.firstIndex(of: listEpisode) {
            selectedEpisodes.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell {
                cell.showTick = false
            }
        }
    }

    // MARK: - Table Config

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        PodcastViewController.allEpisodesSection == section ? UITableView.automaticDimension : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        PodcastViewController.allEpisodesSection == section ? 100 : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        PodcastViewController.allEpisodesSection == section ? searchController?.view : nil
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let castView = view as? UITableViewHeaderFooterView {
            castView.backgroundView?.backgroundColor = UIColor.clear
            castView.contentView.backgroundColor = UIColor.clear
        }
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == PodcastViewController.allEpisodesSection && episodeAtIndexPath(indexPath) != nil
    }

    func episodeAtIndexPath(_ indexPath: IndexPath) -> Episode? {
        guard let listEpisode = episodeInfo[indexPath.section].elements[indexPath.row] as? ListEpisode else { return nil }

        return listEpisode.episode
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == PodcastViewController.allEpisodesSection, episodeAtIndexPath(indexPath) != nil else { return false }

        return Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        isMultiSelectEnabled = true
        multiSelectGestureInProgress = true
    }

    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        multiSelectGestureInProgress = false
    }
}
