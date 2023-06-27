import Foundation

extension StarredViewController: UITableViewDataSource, UITableViewDelegate {
    private static let episodeCellId = "EpisodeCellID"

    func registerCells() {
        starredTable.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: StarredViewController.episodeCellId)
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        starredTable.addGestureRecognizer(longPressRecognizer)
    }

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: starredTable)
            guard let indexPath = starredTable.indexPathForRow(at: touchPoint) else { return }
            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    self.starredTable.selectAllAbove(indexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    self.starredTable.selectAllBelow(indexPath: indexPath)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StarredViewController.episodeCellId, for: indexPath) as! EpisodeCell
        guard let episode = episodes[safe: indexPath.row]?.episode else { return cell }

        cell.delegate = self
        cell.populateFrom(episode: episode, tintColor: nil)
        cell.shouldShowSelect = isMultiSelectEnabled
        if isMultiSelectEnabled {
            cell.showTick = selectedEpisodesContains(uuid: episode.uuid)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    // MARK: - Table Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard episodes[safe: indexPath.row]?.episode != nil else { return nil }

        guard starredTable.isEditing, !multiSelectGestureInProgress else { return indexPath }

        if let selectedEpisode = episodes[safe: indexPath.row] {
            if selectedEpisodes.contains(selectedEpisode) {
                starredTable.delegate?.tableView?(starredTable, didDeselectRowAt: indexPath)
                return nil
            }
            return indexPath
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let episode = episodes[safe: indexPath.row]?.episode, let parentPodcast = episode.parentPodcast() else { return }
        if isMultiSelectEnabled {
            // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
            let listEpisode = episodes[indexPath.row]
            if !multiSelectGestureInProgress {
                // If the episode is already selected move to the end of the array
                selectedEpisodesRemove(uuid: listEpisode.episode.uuid)
            }

            if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: listEpisode.episode.uuid) {
                selectedEpisodes.append(listEpisode)
                // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                if let cell = starredTable.cellForRow(at: indexPath) as? EpisodeCell? {
                    cell?.showTick = true
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)

            let episodeController = EpisodeDetailViewController(episodeUuid: episode.uuid, podcast: parentPodcast, source: .starred, playlist: .starred)
            episodeController.modalPresentationStyle = .formSheet
            present(episodeController, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isMultiSelectEnabled else { return }
        let listEpisode = episodes[indexPath.row]
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

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? 80
    }
}
