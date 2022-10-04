import PocketCastsDataModel
import PocketCastsUtils
import UIKit

extension ListeningHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    private static let episodeCellId = "EpisodeCellID"

    func registerCells() {
        listeningHistoryTable.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: ListeningHistoryViewController.episodeCellId)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        listeningHistoryTable.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: listeningHistoryTable)
            guard let indexPath = listeningHistoryTable.indexPathForRow(at: touchPoint) else { return }
            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    self.listeningHistoryTable.selectAllAbove(indexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    self.listeningHistoryTable.selectAllBelow(indexPath: indexPath)
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
        episodes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes[section].elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ListeningHistoryViewController.episodeCellId, for: indexPath) as! EpisodeCell

        cell.delegate = self
        if let episode = episodes[safe: indexPath.section]?.elements[safe: indexPath.row]?.episode {
            cell.populateFrom(episode: episode, tintColor: nil)
            cell.shouldShowSelect = isMultiSelectEnabled
            if isMultiSelectEnabled {
                cell.showTick = selectedEpisodesContains(uuid: episode.uuid)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard episodes[safe: indexPath.section]?.elements[safe: indexPath.row]?.episode != nil else { return nil }

        guard listeningHistoryTable.isEditing, !multiSelectGestureInProgress else { return indexPath }

        if let selectedEpisode = episodes[indexPath.section].elements[safe: indexPath.row] {
            if selectedEpisodes.contains(selectedEpisode) {
                listeningHistoryTable.delegate?.tableView?(listeningHistoryTable, didDeselectRowAt: indexPath)
                return nil
            }
            return indexPath
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let episode = episodes[safe: indexPath.section]?.elements[safe: indexPath.row]?.episode else { return }

        if isMultiSelectEnabled {
            // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
            let listEpisode = episodes[indexPath.section].elements[indexPath.row]
            if !multiSelectGestureInProgress {
                // If the episode is already selected move to the end of the array
                selectedEpisodesRemove(uuid: listEpisode.episode.uuid)
            }

            if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: listEpisode.episode.uuid) {
                selectedEpisodes.append(listEpisode)
                // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                if let cell = listeningHistoryTable.cellForRow(at: indexPath) as? EpisodeCell? {
                    cell?.showTick = true
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            if episode.downloadFailed() {
                let optionsPicker = OptionsPicker(title: nil)
                let retryAction = OptionAction(label: L10n.retry, icon: nil, action: {
                    NetworkUtils.shared.downloadEpisodeRequested(autoDownloadStatus: .notSpecified, { later in
                        if later {
                            DownloadManager.shared.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: true, autoDownloadStatus: .notSpecified)
                        } else {
                            DownloadManager.shared.addToQueue(episodeUuid: episode.uuid)
                        }
                    }, disallowed: nil)
                })
                optionsPicker.addDescriptiveActions(title: L10n.downloadFailed, message: episode.readableErrorMessage(), icon: "option-alert", actions: [retryAction])
                optionsPicker.show(statusBarStyle: preferredStatusBarStyle)
            } else if let parentPodcast = episode.parentPodcast() {
                let episodeController = EpisodeDetailViewController(episodeUuid: episode.uuid, podcast: parentPodcast, source: .listeningHistory)
                episodeController.modalPresentationStyle = .formSheet
                present(episodeController, animated: true, completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isMultiSelectEnabled else { return }
        let listEpisode = episodes[indexPath.section].elements[indexPath.row]
        if let index = selectedEpisodes.firstIndex(of: listEpisode) {
            selectedEpisodes.remove(at: index)
            if let cell = tableView.cellForRow(at: indexPath) as? EpisodeCell {
                cell.showTick = false
            }
        }
    }

    // MARK: - multi select support

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        Settings.multiSelectGestureEnabled()
    }

    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        isMultiSelectEnabled = true
        multiSelectGestureInProgress = true
    }

    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        multiSelectGestureInProgress = false
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = DateHeadingView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 45))
        sectionHeader.title = titleTextForSection(section)

        return sectionHeader
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? 80
    }

    private func titleTextForSection(_ section: Int) -> String {
        if section >= episodes.count { return "" } // we don't have that many sections

        return episodes[section].model
    }
}
