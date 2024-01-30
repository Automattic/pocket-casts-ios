import PocketCastsDataModel
import UIKit

extension UploadedViewController: UITableViewDataSource, UITableViewDelegate {
    func registerCells() {
        uploadsTable.register(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: "EpisodeCell")
    }

    func registerLongPress() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(tableLongPressed(_:)))
        uploadsTable.addGestureRecognizer(longPressRecognizer)
    }

    // MARK: TableView Datasource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        uploadedEpisodes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
        cell.hidesArtwork = false
        cell.playlist = .files
        cell.delegate = self
        let episode: BaseEpisode = uploadedEpisodes[indexPath.row] as BaseEpisode
        cell.populateFrom(episode: episode, tintColor: ThemeColor.primaryIcon01(), podcastUuid: episode.parentIdentifier())
        cell.shouldShowSelect = isMultiSelectEnabled
        if isMultiSelectEnabled {
            cell.showTick = selectedEpisodesContains(uuid: episode.uuid)
        }
        return cell
    }

    // MARK: - Selection

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard uploadsTable.isEditing, !multiSelectGestureInProgress else { return indexPath }

        if selectedEpisodesContains(uuid: uploadedEpisodes[indexPath.row].uuid) {
            uploadsTable.delegate?.tableView?(uploadsTable, didDeselectRowAt: indexPath)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isMultiSelectEnabled {
            let userEpisode = uploadedEpisodes[indexPath.row]

            if !multiSelectGestureInProgress {
                // If the episode is already selected move to the end of the array
                selectedEpisodesRemove(uuid: userEpisode.uuid)
            }

            if !multiSelectGestureInProgress || multiSelectGestureInProgress, !selectedEpisodesContains(uuid: userEpisode.uuid) {
                selectedEpisodes.append(userEpisode)
                // the cell below is optional because cellForRow only returns a cell if it's visible, and we don't need to tick cells that don't exist
                if let cell = uploadsTable.cellForRow(at: indexPath) as? EpisodeCell? {
                    cell?.showTick = true
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let episode = uploadedEpisodes[indexPath.row]
            userEpisodeDetailVC = UserEpisodeDetailViewController(episodeUuid: episode.uuid)
            userEpisodeDetailVC?.playlist = .files
            userEpisodeDetailVC?.delegate = self
            userEpisodeDetailVC?.animateIn()
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard isMultiSelectEnabled else { return }
        let userEpisode = uploadedEpisodes[indexPath.row]
        if let index = selectedEpisodes.firstIndex(where: { $0.uuid == userEpisode.uuid }) {
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

    // MARK: - Long Press Gesture

    @objc private func tableLongPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: uploadsTable)
            guard let indexPath = uploadsTable.indexPathForRow(at: touchPoint) else { return }
            if isMultiSelectEnabled {
                let optionPicker = OptionsPicker(title: nil, iconTintStyle: .primaryInteractive01)
                let allAboveAction = OptionAction(label: L10n.selectAllAbove, icon: "selectall-up", action: { [] in
                    self.uploadsTable.selectAllAbove(indexPath: indexPath)
                })

                let allBelowAction = OptionAction(label: L10n.selectAllBelow, icon: "selectall-down", action: { [] in
                    self.uploadsTable.selectAllBelow(indexPath: indexPath)
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
}
