import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import PocketCastsServer

extension PodcastViewController: UITableViewDataSource, UITableViewDelegate {
    private static let episodeCellId = "EpisodeCell"
    private static let headerCellId = "HeaderCell"
    private static let limitCellId = "LimitCell"
    private static let noSearchResultsCell = "NoSearchResults"
    private static let allArchivedCellId = "AllArchivedCell"
    private static let groupHeadingCellId = "GroupHeading"

    private enum SimilarShowsSection {
        case header
        case podroll
        case podcasts
    }

    private func similarShowsSectionType(for section: Int) -> SimilarShowsSection {
        if section == PodcastViewController.headerSection {
            return .header
        }

        if section == 1, (recommendations?.podroll?.count ?? 0) > 0 {
            return .podroll
        }

        return .podcasts
    }

    func registerCells() {
        episodesTable.register(PodcastTableViewCell.self, forCellReuseIdentifier: PodcastTableViewCell.reuseIdentifier)
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
        if sender.state == .began && currentViewMode != .similarShows {
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
        if loadingPodcastInfo { return 0 }

        switch currentViewMode {
        case .episodes:
            return 2
        case .bookmarks:
            return 0 // Bookmarks are shown in a separate controller
        case .similarShows:
            var sectionCount = 1 // Always show header section
            if (recommendations?.podroll?.count ?? 0) > 0 {
                sectionCount += 1 // Add podroll section if it has content
            }
            if (recommendations?.podcasts?.count ?? 0) > 0 {
                sectionCount += 1 // Add podcasts section if it has content
            }
            return sectionCount
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadingPodcastInfo { return 0 }

        switch currentViewMode {
        case .episodes:
            return episodeInfo[safe: section]?.elements.count ?? 0
        case .bookmarks:
            return 0
        case .similarShows:
            switch similarShowsSectionType(for: section) {
            case .header:
                return 1
            case .podroll:
                return recommendations?.podroll?.count ?? 0
            case .podcasts:
                return recommendations?.podcasts?.count ?? 0
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentViewMode {
        case .episodes:
            if indexPath.section == PodcastViewController.headerSection {
                if FeatureFlag.podcastViewChanges.enabled {
                    let cell = podcastHeaderCell
                    return cell
                } else {
                    let cell = podcastHeadingCell
                    cell.populateFrom(tintColor: podcast?.iconTintColor(), delegate: self, parentController: self)
                    cell.buttonsEnabled = !isMultiSelectEnabled
                    return cell
                }
            }

            guard let itemAtRow = episodeInfo[safe: indexPath.section]?.elements[safe: indexPath.row] as? ListItem else {
                FileLog.shared.addMessage("EpisodeInfo missing ListItem in section \(indexPath.section), row \(indexPath.row)")
                return UITableViewCell()
            }
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

        case .bookmarks:
            return UITableViewCell()

        case .similarShows:
            switch similarShowsSectionType(for: indexPath.section) {
            case .header:
                if FeatureFlag.podcastViewChanges.enabled {
                    let cell = podcastHeaderCell
                    return cell
                } else {
                    let cell = podcastHeadingCell
                    cell.populateFrom(tintColor: podcast?.iconTintColor(), delegate: self, parentController: self)
                    cell.buttonsEnabled = !isMultiSelectEnabled
                    return cell
                }
            case .podroll:
                guard let podcast = recommendations?.podroll?[indexPath.row] else {
                    assertionFailure("[PodcastViewController] Similar Shows - Missing podcast")
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastTableViewCell.reuseIdentifier, for: indexPath) as! PodcastTableViewCell
                cell.configure(with: podcast)
                return cell
            case .podcasts:
                guard let podcast = recommendations?.podcasts?[indexPath.row] else {
                    assertionFailure("[PodcastViewController] Similar Shows - Missing podcast")
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastTableViewCell.reuseIdentifier, for: indexPath) as! PodcastTableViewCell
                cell.configure(with: podcast)
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if FeatureFlag.podcastViewChanges.enabled, indexPath.section == PodcastViewController.headerSection {
            return podcastHeaderCell.rowHeight
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? 80
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Special handling for episodes only to deal with multi gesture
        guard currentViewMode == .episodes else { return indexPath }

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
        switch currentViewMode {
        case .episodes:
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

        case .bookmarks:
            break

        case .similarShows:
            switch similarShowsSectionType(for: indexPath.section) {
            case .header:
                if let cell = tableView.cellForRow(at: indexPath) as? PodcastHeadingTableCell, !isMultiSelectEnabled {
                    cell.toggleExpanded(delegate: self)
                }
            case .podroll:
                guard let selectedPodcast = recommendations?.podroll?[indexPath.row] else { return }
                let info = PodcastInfo(selectedPodcast)
                let podcastController = PodcastViewController(podcastInfo: info, existingImage: nil)
                navigationController?.pushViewController(podcastController, animated: true)
            case .podcasts:
                guard let selectedPodcast = recommendations?.podcasts?[indexPath.row] else { return }
                let info = PodcastInfo(selectedPodcast)
                let podcastController = PodcastViewController(podcastInfo: info, existingImage: nil)
                navigationController?.pushViewController(podcastController, animated: true)
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
        if currentViewMode == .similarShows {
            switch similarShowsSectionType(for: section) {
            case .podcasts:
                if similarShowsSectionType(for: section - 1) == .header {
                    return 16 // Add additional spacing between header & podcasts
                }
            case .podroll:
                return 40
            default:
                return CGFloat.leastNonzeroMagnitude
            }
        }
        return PodcastViewController.allEpisodesSection == section ? UITableView.automaticDimension : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if currentViewMode == .similarShows {
            return CGFloat.leastNonzeroMagnitude
        }
        return PodcastViewController.allEpisodesSection == section ? 100 : CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if currentViewMode == .similarShows {
            switch similarShowsSectionType(for: section) {
            case .podroll:
                return 24 // Divider between podroll and podcasts
            default:
                return CGFloat.leastNonzeroMagnitude
            }
        }
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard currentViewMode == .similarShows else { return nil }

        switch similarShowsSectionType(for: section) {
        case .podroll:
            return dividerView()
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard currentViewMode == .similarShows else {
            return currentViewMode == .episodes ? searchController?.view : nil
        }

        switch similarShowsSectionType(for: section) {
        case .podroll:
            return PodrollHeaderView()
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let castView = view as? UITableViewHeaderFooterView {
            castView.backgroundView?.backgroundColor = UIColor.clear
            castView.contentView.backgroundColor = UIColor.clear
        }
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard currentViewMode != .similarShows else { return false }
        return indexPath.section == PodcastViewController.allEpisodesSection && episodeAtIndexPath(indexPath) != nil
    }

    func episodeAtIndexPath(_ indexPath: IndexPath) -> Episode? {
        guard let listEpisode = episodeInfo[safe: indexPath.section]?.elements[safe: indexPath.row] as? ListEpisode else { return nil }

        return listEpisode.episode
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        guard currentViewMode != .similarShows,
              indexPath.section == PodcastViewController.allEpisodesSection,
              episodeAtIndexPath(indexPath) != nil else { return false }

        return Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        isMultiSelectEnabled = true
        multiSelectGestureInProgress = true
    }

    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        multiSelectGestureInProgress = false
    }

    private func dividerView() -> UIView {
        let footerView = UIView()
        footerView.backgroundColor = .clear

        let divider = ThemeDividerView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 15),
            divider.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -15),
            divider.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        return footerView
    }
}
