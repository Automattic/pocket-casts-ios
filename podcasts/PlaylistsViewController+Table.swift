import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import SwiftUI

extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {
    private static let playlistCellId = "PlaylistCell"

    func registerCells() {
        filtersTable.register(UINib(nibName: "FilterNameCell", bundle: nil), forCellReuseIdentifier: PlaylistsViewController.playlistCellId)
        if FeatureFlag.playlistsRebranding.enabled {
            filtersTable.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlists.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FeatureFlag.playlistsRebranding.enabled ? 81.0 : 72.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if FeatureFlag.playlistsRebranding.enabled {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.reuseIdentifier, for: indexPath) as! PlaylistCell
            if let playlist = playlists[safe: indexPath.row] {
                cell.accessoryType = .none
                cell.configure(playlist: playlist)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistsViewController.playlistCellId, for: indexPath) as! FilterNameCell

        if let filter = playlists[safe: indexPath.row] {
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

        if let filter = playlists[safe: indexPath.row] {
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
        if editingStyle == .delete, let filter = playlists[safe: indexPath.row] {
            PlaylistManager.delete(filter: filter, fireEvent: false)
            playlists.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .top)
            tableView.endUpdates()

            Analytics.track(.filterDeleted)
        }
    }

    // MARK: - Cell reordering

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath { return }

        let movedObject = playlists[sourceIndexPath.row]
        playlists.remove(at: sourceIndexPath.row)
        playlists.insert(movedObject, at: destinationIndexPath.row)

        // ok, we've now sorted the list that needed sorting, update the sort positions in the DB and mark that list as not synced
        for (index, filter) in playlists.enumerated() {
            DataManager.sharedManager.updatePosition(filter: filter, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.filterChanged)

        Analytics.track(.filterListReordered)
    }
}

extension PlaylistsViewController {
    func showNewFilterTip() {
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let idealSize = CGSizeMake(290, 100)
        let tipView = TipViewStatic(title: L10n.filtersTipViewTitle,
                                    message: L10n.filtersTipViewDescription,
                              onTap: { [weak self] in
            self?.dismissTipView()
        })
            .frame(idealWidth: idealSize.width, minHeight: idealSize.height)
            .setupDefaultEnvironment()
        vc.rootView = AnyView(tipView)
        vc.view.backgroundColor = .clear
        vc.view.clipsToBounds = false
        vc.modalPresentationStyle = .popover
        vc.sizingOptions = [.preferredContentSize]
        if let popoverPresentationController = vc.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.permittedArrowDirections = [.up]
            popoverPresentationController.sourceView = newFilterButton
            popoverPresentationController.sourceRect = newFilterButton.bounds.offsetBy(dx: 0, dy: 10)
            popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        }
        newFilterTip = vc
        Analytics.track(.filterTooltipShown)
        present(vc, animated: true) {
            Settings.shouldShowNewFilterTip = false
        }
    }

    private func dismissTipView() {
        dismiss(animated: true, completion: nil)
        Analytics.track(.filterTooltipClosed)
    }

    func showNewFilterTipIfNeeded() {
        guard
            Settings.shouldShowNewFilterTip,
            newFilterTip == nil
        else {
            return
        }
        showNewFilterTip()
    }
}

extension PlaylistsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        dismissTipView()
    }
}
