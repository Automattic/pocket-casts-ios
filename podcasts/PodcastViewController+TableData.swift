import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import PocketCastsServer
import SwiftUI

extension PodcastViewController: UITableViewDataSource, UITableViewDelegate {
    private static let episodeCellId = "EpisodeCell"
    private static let headerCellId = "HeaderCell"
    private static let limitCellId = "LimitCell"
    private static let noSearchResultsCell = "NoSearchResults"
    private static let groupHeadingCellId = "GroupHeading"
    private static let emptyStateCellId = "EmptyStateCell"
    private static let loadingCellId = "LoadingCell"

    private enum YouMightLikeSection {
        case header
        case loading
        case podroll
        case podcasts
        case empty
    }

    private func youMightLikeSectionType(for section: Int) -> YouMightLikeSection {
        if section == PodcastViewController.headerSection {
            return .header
        }

        if isLoadingRecommendations.value {
            return .loading
        }

        if section == 1, (recommendations?.podroll?.count ?? 0) > 0 {
            return .podroll
        }

        if section == 1, (recommendations?.podroll?.count ?? 0) == 0, (recommendations?.podcasts?.count ?? 0) == 0 {
            return .empty
        }

        return .podcasts
    }

    func registerCells() {
        episodesTable.register(PodcastTableViewCell.self, forCellReuseIdentifier: PodcastTableViewCell.reuseIdentifier)
        episodesTable.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.episodeCellId)
        episodesTable.register(UINib(nibName: "EpisodeLimitCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.limitCellId)
        episodesTable.register(UINib(nibName: "HeadingCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.groupHeadingCellId)
        episodesTable.register(UINib(nibName: "NoSearchResultsCell", bundle: nil), forCellReuseIdentifier: PodcastViewController.noSearchResultsCell)
        episodesTable.register(EmptyStateCell.self, forCellReuseIdentifier: EmptyStateCell.reuseIdentifier)
        episodesTable.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        episodesTable.register(BookmarksHostingCell.self, forCellReuseIdentifier: BookmarksHostingCell.reuseIdentifier)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        episodesTable.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began && currentViewMode != .youMightLike {
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
            return 2 // Header + Bookmarks
        case .youMightLike:
            if isLoadingRecommendations.value || !hasSimilarShows.value {
                return 2 // Header + Loading
            }

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
            return section == PodcastViewController.headerSection ? 1 : 1 // Header + Bookmarks list
        case .youMightLike:
            switch youMightLikeSectionType(for: section) {
            case .header, .loading, .empty:
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
                let cell = podcastHeaderCell
                return cell
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
                let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
                cell.configure(title: L10n.discoverNoEpisodesFound, message: L10n.discoverNoPodcastsFoundMsg, icon: {
                    Image(systemName: "info.circle")
                })
                return cell
            } else if let archivedPlaceholder = itemAtRow as? AllArchivedPlaceholder {
                let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
                cell.configure(title: L10n.episodeFilterNoEpisodesTitle, message: archivedPlaceholder.message, icon: {
                    Image(systemName: "info.circle")
                }, actions: [
                    .init(title: L10n.podcastShowArchived, action: { [weak self] in
                        guard let self else { return }
                        self.searchController?.showHideArchiveTapped(self)
                    })
                ])
                return cell
            } else if let heading = itemAtRow as? ListHeader {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.groupHeadingCellId, for: indexPath) as! HeadingCell
                cell.heading.text = heading.headerTitle
                if podcast?.episodeGrouping == PodcastGrouping.season.rawValue {
                    cell.button.isHidden = false
                    cell.button.isEnabled = !isMultiSelectEnabled
                    cell.action = { [weak self] in
                        self?.showOptionsFor(season: heading.sectionNumber)
                    }
                } else {
                    cell.button.isHidden = true
                    cell.action = nil
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastViewController.limitCellId, for: indexPath) as! EpisodeLimitCell
                return cell
            }

        case .bookmarks:
            if indexPath.section == PodcastViewController.headerSection {
                let cell = podcastHeaderCell
                return cell
            } else {
                guard let bookmarkViewModel = bookmarkViewModel else {
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: BookmarksHostingCell.reuseIdentifier, for: indexPath) as! BookmarksHostingCell
                cell.configure(with: bookmarkViewModel) { [weak self] state in
                    self?.updateBookmarksActionBar(state: state, viewModel: bookmarkViewModel)
                }
                return cell
            }

        case .youMightLike:
            switch youMightLikeSectionType(for: indexPath.section) {
            case .header:
                let cell = podcastHeaderCell
                return cell
            case .loading:
                let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as! LoadingCell
                return cell
            case .empty:
                let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateCell.reuseIdentifier, for: indexPath) as! EmptyStateCell
                cell.configure(title: L10n.failedRecommendations, icon: {
                    Image(systemName: "exclamationmark.circle")
                }, actions: [
                    .init(title: L10n.tryAgain, action: {
                        Task { [weak self] in
                            guard !Task.isCancelled else { return }
                            await self?.loadRecommendations()
                        }
                    })
                ])
                return cell
            case .podroll:
                guard let podcast = recommendations?.podroll?[indexPath.row] else {
                    assertionFailure("[PodcastViewController] You Might Like Tab - Missing podroll podcast")
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastTableViewCell.reuseIdentifier, for: indexPath) as! PodcastTableViewCell
                cell.configure(with: podcast, datetime: nil) { viewModel in
                    let properties = ["podcast_uuid": viewModel.uuid]
                    Analytics.track(.podcastScreenPodrollPodcastSubscribed, properties: properties)
                }
                return cell
            case .podcasts:
                guard let podcast = recommendations?.podcasts?[indexPath.row] else {
                    assertionFailure("[PodcastViewController] You Might Like Tab - Missing podcast")
                    return UITableViewCell()
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: PodcastTableViewCell.reuseIdentifier, for: indexPath) as! PodcastTableViewCell
                cell.configure(with: podcast, datetime: recommendations?.datetime, onSubscribe: { viewModel in
                    var properties = ["podcast_uuid": viewModel.uuid]
                    properties["list_datetime"] = viewModel.datetime
                    Analytics.track(.podcastScreenYouMightLikeSubscribed, properties: properties)
                })
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == PodcastViewController.headerSection {
            return podcastHeaderCell.rowHeight
        }

        if currentViewMode == .bookmarks && indexPath.section != PodcastViewController.headerSection {
            // For bookmarks, we need to calculate the height dynamically
            return UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? 80
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

                if indexPath.section == PodcastViewController.allEpisodesSection {
                    guard let podcast = podcast, let episode = episodeAtIndexPath(indexPath) else { return }

                    let episodeController = EpisodeDetailViewController(episode: episode, podcast: podcast, source: .podcastScreen, playlist: .podcast(uuid: podcast.uuid))
                    episodeController.modalPresentationStyle = .formSheet
                    present(episodeController, animated: true, completion: nil)
                }
            }

        case .bookmarks:
            if let headerCell = tableView.cellForRow(at: indexPath) as? PodcastHeaderCell,
               !isMultiSelectEnabled,
               indexPath.section == PodcastViewController.headerSection {
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 15)) {
                    headerCell.viewModel.toggleExpanded()
                }
            }
        case .youMightLike:
            switch youMightLikeSectionType(for: indexPath.section) {
            case .header:
                break
            case .loading, .empty:
                break // Do nothing for these state cells
            case .podroll:
                guard let selectedPodcast = recommendations?.podroll?[indexPath.row] else { return }
                var properties: [String: Any] = [:]
                if let uuid = selectedPodcast.uuid {
                    properties["podcast_uuid"] = uuid
                }
                Analytics.track(.podcastScreenPodrollPodcastTapped, properties: properties)
                let info = PodcastInfo(selectedPodcast)
                let podcastController = PodcastViewController(podcastInfo: info, existingImage: nil)
                navigationController?.pushViewController(podcastController, animated: true)
            case .podcasts:
                guard let selectedPodcast = recommendations?.podcasts?[indexPath.row] else { return }
                var properties: [String: Any] = [:]
                if let datetime = recommendations?.datetime {
                    properties["list_datetime"] = datetime
                }
                if let uuid = selectedPodcast.uuid {
                    properties["podcast_uuid"] = uuid
                }
                Analytics.track(.podcastScreenYouMightLikeTapped, properties: properties)
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

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return headerHeightValue(for: currentViewMode, section: section, estimated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard currentViewMode == .youMightLike else {
            // Episodes show a UIKit search header; Bookmarks embeds search inside its cell.
            return currentViewMode == .episodes ? searchController?.view : nil
        }

        switch youMightLikeSectionType(for: section) {
        case .podroll:
            let image = UIImage(systemName: "mic")?.withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
            let headerView = YouMightLikeSectionHeaderView(image: image, title: L10n.podcastPodrollHeader)
            headerView.onTapped = { [weak self] in
                guard let self = self else { return }
                BottomSheetSwiftUIWrapper.present(
                    PodrollInformationModalView(onDismiss: { [weak self] in
                        self?.presentedViewController?.dismiss(animated: true, completion: nil)
                    }).environmentObject(Theme.sharedTheme),
                    autoSize: true,
                    in: self
                )
                Analytics.track(.podcastScreenPodrollInformationModelShown)
            }
            return headerView
        case .podcasts:
            if youMightLikeSectionType(for: section - 1) == .podroll {
                let title: String
                if let podcastTitle = podcast?.title {
                    title = L10n.podcastSimilarHeader(podcastTitle)
                } else {
                    title = L10n.podcastSimilarGenericHeader
                }
                let headerView = YouMightLikeSectionHeaderView(image: UIImage(named: "stacked_squares"), title: title)
                return headerView
            }
            return nil
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if currentViewMode == .youMightLike {
            switch youMightLikeSectionType(for: section) {
            case .header:
                switch youMightLikeSectionType(for: section + 1) {
                case .podroll:
                    return 10 // Only the podroll needs extra spacing for the header
                default:
                    return CGFloat.leastNonzeroMagnitude
                }
            case .podroll:
                return 15
            default:
                return CGFloat.leastNonzeroMagnitude
            }
        }
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeightValue(for: currentViewMode, section: section, estimated: false)
    }

    private func headerHeightValue(for mode: ViewMode, section: Int, estimated: Bool) -> CGFloat {
        switch mode {
        case .bookmarks:
            // Remove default header spacing above Bookmarks list so the search field aligns under tabs
            return .leastNonzeroMagnitude
        case .youMightLike:
            switch youMightLikeSectionType(for: section) {
            case .podroll:
                return 34
            case .podcasts:
                switch youMightLikeSectionType(for: section - 1) {
                case .header:
                    return 16 // Padding between header
                case .podroll:
                    return 34
                default:
                    return .leastNonzeroMagnitude
                }
            default:
                return .leastNonzeroMagnitude
            }
        case .episodes:
            if PodcastViewController.allEpisodesSection == section {
                return estimated ? 100 : UITableView.automaticDimension
            }
            return .leastNonzeroMagnitude
        }
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard currentViewMode != .youMightLike else { return false }
        return indexPath.section == PodcastViewController.allEpisodesSection && episodeAtIndexPath(indexPath) != nil
    }

    func episodeAtIndexPath(_ indexPath: IndexPath) -> Episode? {
        guard let listEpisode = episodeInfo[safe: indexPath.section]?.elements[safe: indexPath.row] as? ListEpisode else { return nil }

        return listEpisode.episode
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        guard currentViewMode != .youMightLike,
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
}
