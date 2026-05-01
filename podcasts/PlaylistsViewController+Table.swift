import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import UIKit
import SwiftUI

extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {
    private static let playlistCellId = "PlaylistCell"

    func registerCells() {
        if FeatureFlag.playlistsRebranding.enabled {
            filtersTable.register(NewPlaylistCell.self, forCellReuseIdentifier: NewPlaylistCell.reuseIdentifier)
        } else {
            filtersTable.register(UINib(nibName: "FilterNameCell", bundle: nil), forCellReuseIdentifier: PlaylistsViewController.playlistCellId)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listPlaylistItems.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return FeatureFlag.playlistsRebranding.enabled ? NewPlaylistCell.cellHeight : FilterNameCell.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if FeatureFlag.playlistsRebranding.enabled {
            let cell = cell(tableView, for: NewPlaylistCell.reuseIdentifier) as! NewPlaylistCell
            if cell.tag != indexPath.row { cell.reset() }
            cell.tag = indexPath.row
            if let playlist = listPlaylistItems[safe: indexPath.row]?.playlist {
                cell.set(playlistName: playlist.playlistName, isManualPlaylist: playlist.manual)
                cell.loadMetadata(for: playlist)
                cell.hideSeparator(indexPath.row == listPlaylistItems.count - 1)
            }
            return cell
        }

        let cell = cell(tableView, for: PlaylistsViewController.playlistCellId) as! FilterNameCell

        if let filter = listPlaylistItems[safe: indexPath.row]?.playlist {
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
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? NewPlaylistCell {
                return cell
            }
            return NewPlaylistCell(style: .default, reuseIdentifier: identifier)
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
        if informationalBannerCoordinator.shouldShowBanner() {
            return UITableView.automaticDimension
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !informationalBannerCoordinator.shouldShowBanner() {
            return nil
        }
        return informationalBannerCoordinator.tableHeaderView(size: CGSize(width: filtersTable.bounds.width, height: 135)) {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.filtersTable.reloadData()
            }
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if informationalBannerCoordinator.shouldShowBanner() {
            return 135
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let filter = listPlaylistItems[safe: indexPath.row]?.playlist {
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
        if editingStyle == .delete, let playlist = listPlaylistItems[safe: indexPath.row]?.playlist {
            if FeatureFlag.playlistsRebranding.enabled {
                showDeleteOptionPicker(for: playlist, at: indexPath, in: tableView)
            } else {
                delete(playlist: playlist, at: indexPath, in: tableView)
            }
        }
    }

    // MARK: - Cell reordering

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath { return }

        let movedObject = listPlaylistItems[sourceIndexPath.row]
        listPlaylistItems.remove(at: sourceIndexPath.row)
        listPlaylistItems.insert(movedObject, at: destinationIndexPath.row)

        // ok, we've now sorted the list that needed sorting, update the sort positions in the DB and mark that list as not synced
        for (index, filter) in listPlaylistItems.enumerated() {
            DataManager.sharedManager.updatePosition(playlist: filter.playlist, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

        Analytics.track(.filterListReordered)
    }
}

// MARK: - Delete

extension PlaylistsViewController {
    fileprivate func showDeleteOptionPicker(for playlist: EpisodeFilter, at indexPath: IndexPath, in tableView: UITableView) {
        let playlistType = playlist.manual ? "manual" : "smart"
        let analyticsProperties = ["filter_type": playlistType]
        Analytics.track(.filterDeleteTriggered, properties: analyticsProperties)

        if FeatureFlag.liquidGlass.enabled {
            let alert = UIAlertController(title: L10n.alertDeletePlaylist, message: L10n.playlistsDeleteAlertMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L10n.delete, style: .destructive) { [weak self] _ in
                self?.delete(playlist: playlist, at: indexPath, in: tableView)
            })
            alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel) { _ in
                Analytics.track(.filterDeleteDismissed, properties: analyticsProperties)
            })
            present(alert, animated: true)
        } else {
            let delete = OptionAction(label: L10n.delete, icon: nil, action: { [weak self] in
                self?.delete(playlist: playlist, at: indexPath, in: tableView)
            })
            delete.destructive = true
            let picker = OptionsPicker(title: "")
            picker.addDescriptiveActions(title: L10n.playlistsDeleteAlertTitle, message: L10n.playlistsDeleteAlertMessage, icon: "option-alert", actions: [delete])
            picker.setNoActionCallback {
                Analytics.track(.filterDeleteDismissed, properties: analyticsProperties)
            }
            picker.show(statusBarStyle: .default)
        }
    }

    fileprivate func delete(playlist: EpisodeFilter, at indexPath: IndexPath, in tableView: UITableView) {
        PlaylistManager.delete(playlist: playlist, fireEvent: false)
        listPlaylistItems.remove(at: indexPath.row)
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .top)
        tableView.endUpdates()

        var properties: [AnyHashable: Any]? = [:]

        if FeatureFlag.playlistsRebranding.enabled {
            properties?["filter_type"] = playlist.manual ? "manual" : "smart"
        }

        Analytics.track(.filterDeleted, properties: properties)
    }
}

// MARK: - Tip

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
        dismiss(animated: true) { [weak self] in
            self?.newFilterTip = nil
        }
        Analytics.track(.filterTooltipClosed)
    }

    func showPlaylistsTipIfNeeded() {
        if !FeatureFlag.playlistsRebranding.enabled {
            showNewFilterTip()
            return
        }

        if SyncManager.isUserLoggedIn(),
           Settings.shouldShowNewFilterTip,
           !hasPremadePlaylists(),
           newFilterTip == nil {
            showNewFilterTip()
            return
        }

        if Settings.firstTimePlaylistCreated,
           Settings.shouldShowDragAndDropTip,
           !presentingPlaylistDetail,
           newFilterTip == nil {
            presentPlaylistsDragAndDropTip()
            return
        }
    }

    private func hasPremadePlaylists() -> Bool {
        let premadePlaylistUuids: Set<String> = [
            PlaylistManager.DefaultUUIDs.newReleases,
            PlaylistManager.DefaultUUIDs.inProgress
        ]
        let playlistsUUID = listPlaylistItems.map { $0.playlist.uuid }
        let playlistsUUIDSet: Set<String> = Set(playlistsUUID)
        if playlistsUUIDSet.count > premadePlaylistUuids.count || premadePlaylistUuids != playlistsUUIDSet {
            return true
        }
        return false
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
        guard let indexPath = filtersTable.indexPathsForVisibleRows?.last, !listPlaylistItems.isEmpty else { return nil }
        return tip(
            title: L10n.smartPlaylistsTipViewTitle,
            message: L10n.smartPlaylistsTipViewDescription,
            sourceView: filtersTable,
            sourceRect: filtersTable.rectForRow(at: indexPath)
        )
    }

    private func presentPlaylistsDragAndDropTip() {
        guard
            let indexPath = filtersTable.indexPathsForVisibleRows?.first,
            let cell = filtersTable.cellForRow(at: indexPath) as? NewPlaylistCell,
            !listPlaylistItems.isEmpty
        else { return }
        let tip = tip(
            title: L10n.playlistsTipDragAndDropTitle,
            message: L10n.playlistsTipDragAndDropDescription,
            sourceView: cell.artworkImageSource,
            sourceRect: cell.artworkImageSource.bounds
        )
        guard let tip else { return }
        newFilterTip = tip

        //TODO: Add analytics

        present(tip, animated: true) {
            Settings.firstTimePlaylistCreated = false
            Settings.shouldShowDragAndDropTip = false
        }
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
        let movedObject = listPlaylistItems[indexPath.row]
        let itemProvider = NSItemProvider(object: "\(movedObject.id)" as NSString)
        return [UIDragItem(itemProvider: itemProvider)]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        coordinator.items.forEach { item in
            if let sourceIndexPath = item.sourceIndexPath {
                tableView.performBatchUpdates {
                    let movedItem = listPlaylistItems.remove(at: sourceIndexPath.row)
                    listPlaylistItems.insert(movedItem, at: destinationIndexPath.row)
                    tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
                }
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            }
        }

        for (index, playlist) in listPlaylistItems.enumerated() {
            DataManager.sharedManager.updatePosition(playlist: playlist.playlist, newPosition: Int32(index))
        }

        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged)

        Analytics.track(.filterListReordered)
    }
}
