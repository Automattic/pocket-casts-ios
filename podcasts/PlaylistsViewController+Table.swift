import PocketCastsDataModel
import UIKit

extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {
    private static let playlistCellId = "PlaylistCell"

    func registerCells() {
        filtersTable.register(UINib(nibName: "FilterNameCell", bundle: nil), forCellReuseIdentifier: PlaylistsViewController.playlistCellId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        episodeFilters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistsViewController.playlistCellId, for: indexPath) as! FilterNameCell

        if let filter = episodeFilters[safe: indexPath.row] {
            cell.filterName.text = filter.playlistName
            cell.filterImage.image = filter.iconImage()
            cell.filterImage.tintColor = filter.playlistColor()
            cell.filterName.textColor = AppTheme.mainTextColor()
            cell.episodeCount.textColor = ThemeColor.primaryText02()
            cell.accessoryType = .disclosureIndicator

            if cell.tag != indexPath.row { cell.episodeCount?.text = nil }
            cell.tag = indexPath.row // store this so that we know when the cell has been reused to not set the number on it
            DispatchQueue.global(qos: .default).async { () in
                let count = DataManager.sharedManager.episodeCount(forFilter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries())
                DispatchQueue.main.async { () in
                    if cell.tag != indexPath.row { return }

                    cell.episodeCount?.text = "\(count)"
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let filter = episodeFilters[safe: indexPath.row] {
            showFilter(filter)
        }
    }

    // MARK: - Editing

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let filter = episodeFilters[safe: indexPath.row] {
            PlaylistManager.delete(filter: filter, fireEvent: false)
            episodeFilters.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .top)
            tableView.endUpdates()

            Analytics.track(.filterDeleted)
        }
    }

    // MARK: - Cell reordering

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath { return }

        let movedObject = episodeFilters[sourceIndexPath.row]
        episodeFilters.remove(at: sourceIndexPath.row)
        episodeFilters.insert(movedObject, at: destinationIndexPath.row)

        // ok, we've now sorted the list that needed sorting, update the sort positions in the DB and mark that list as not synced
        for (index, filter) in episodeFilters.enumerated() {
            DataManager.sharedManager.updatePosition(filter: filter, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)

        Analytics.track(.filterListReordered)
    }
}
