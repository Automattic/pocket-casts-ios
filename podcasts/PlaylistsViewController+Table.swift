import PocketCastsDataModel
import PocketCastsUtils
import UIKit
import SwiftUI

extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {
    private static let playlistCellId = "PlaylistCell"

    func registerCells() {
        if FeatureFlag.playlistsRebranding.enabled {
            filtersTable.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
        } else {
            filtersTable.register(UINib(nibName: "FilterNameCell", bundle: nil), forCellReuseIdentifier: PlaylistsViewController.playlistCellId)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlists.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FeatureFlag.playlistsRebranding.enabled ? PlaylistCell.cellHeight : FilterNameCell.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if FeatureFlag.playlistsRebranding.enabled {
            let cell = cell(tableView, for: PlaylistCell.reuseIdentifier) as! PlaylistCell
            if let playlist = playlists[safe: indexPath.row] {
                cell.configure(playlist: playlist, isLastRow: indexPath.row == playlists.count - 1)
            }
            return cell
        }

        let cell = cell(tableView, for: PlaylistsViewController.playlistCellId) as! FilterNameCell

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
                let count = DataManager.sharedManager.episodeCount(for: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries())
                DispatchQueue.main.async { () in
                    if cell.tag != indexPath.row { return }

                    cell.episodeCount?.text = "\(count)"
                }
            }
        }

        return cell
    }

    private func cell(_ tableView: UITableView, for identifier: String) -> ThemeableCell? {
        if FeatureFlag.playlistsRebranding.enabled {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? PlaylistCell {
                return cell
            }
            return PlaylistCell(style: .default, reuseIdentifier: identifier)
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FilterNameCell {
                return cell
            }
            let nib = UINib(nibName: "FilterNameCell", bundle: nil)
            let objects = nib.instantiate(withOwner: nil, options: nil)
            if let cell = objects.first as? FilterNameCell {
                return cell
            }
        }
        return nil
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
        if editingStyle == .delete, let playlist = playlists[safe: indexPath.row] {
            PlaylistManager.delete(playlist: playlist, fireEvent: false)
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
            DataManager.sharedManager.updatePosition(playlist: filter, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

        Analytics.track(.filterListReordered)
    }
}

extension PlaylistsViewController {
    func showNewFilterTip() {
        guard
            let vc = FeatureFlag.playlistsRebranding.enabled ? smartPlaylistsTip() : filtersTip()
        else {
            return
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

    private func filtersTip() -> UIHostingController<AnyView>? {
        return tip(
            title: L10n.filtersTipViewTitle,
            message: L10n.filtersTipViewDescription,
            sourceView: newFilterButton,
            sourceRect: newFilterButton.bounds.offsetBy(dx: 0, dy: 10)
        )
    }

    private func smartPlaylistsTip() -> UIHostingController<AnyView>? {
        guard let indexPath = filtersTable.indexPathsForVisibleRows?.last, !playlists.isEmpty else { return nil }
        return tip(
            title: L10n.smartPlaylistsTipViewTitle,
            message: L10n.smartPlaylistsTipViewDescription,
            sourceView: filtersTable,
            sourceRect: filtersTable.rectForRow(at: indexPath)
        )
    }

    private func tip(
        idealSize: CGSize = CGSizeMake(290, 100),
        title: String,
        message: String,
        sourceView: UIView?,
        sourceRect: CGRect
    ) -> UIHostingController<AnyView>? {
        let vc = UIHostingController(rootView: AnyView (EmptyView()) )
        let tipView = TipViewStatic(title: title,
                                    message: message,
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
        guard let popoverPresentationController = vc.popoverPresentationController else {
            return nil
        }
        popoverPresentationController.delegate = self
        popoverPresentationController.permittedArrowDirections = [.up]
        popoverPresentationController.sourceView = sourceView
        popoverPresentationController.sourceRect = sourceRect
        popoverPresentationController.backgroundColor = ThemeColor.primaryUi01()
        return vc
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

extension PlaylistsViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let movedObject = playlists[indexPath.row]
        let itemProvider = NSItemProvider(object: "\(movedObject.id)" as NSString)
        return [UIDragItem(itemProvider: itemProvider)]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        coordinator.items.forEach { item in
            if let sourceIndexPath = item.sourceIndexPath {
                tableView.performBatchUpdates {
                    let movedItem = playlists.remove(at: sourceIndexPath.row)
                    playlists.insert(movedItem, at: destinationIndexPath.row)
                    tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
                }
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            }
        }

        for (index, playlist) in playlists.enumerated() {
            DataManager.sharedManager.updatePosition(playlist: playlist, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

        Analytics.track(.filterListReordered)
    }
}
