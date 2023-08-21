import PocketCastsDataModel
import UIKit

extension ShelfActionsViewController: UITableViewDelegate, UITableViewDataSource {
    private static let shelfCellId = "ShelfCell"

    private static let shortcutSection = 0
    private static let menuSection = 1

    func registerCells() {
        actionsTable.register(UINib(nibName: "ShelfCell", bundle: nil), forCellReuseIdentifier: ShelfActionsViewController.shelfCellId)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        tableView.isEditing ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEditing {
            if section == ShelfActionsViewController.shortcutSection {
                return Constants.Limits.maxShelfActions
            }

            return allActions.count - Constants.Limits.maxShelfActions
        } else {
            return extraActions.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShelfActionsViewController.shelfCellId, for: indexPath) as! ShelfCell

        guard let playingEpisode = PlaybackManager.shared.currentEpisode() else { return cell }

        let action = actionAt(indexPath: indexPath, isEditing: tableView.isEditing)

        if !tableView.isEditing {
            cell.actionName.text = action.title(episode: playingEpisode)
            if action != .routePicker {
                cell.actionIcon.image = UIImage(named: action.iconName(episode: playingEpisode))
                cell.customViewContainer.removeAllSubviews()
            } else if let routePickerView = playerActionsDelegate?.sharedRoutePicker(largeSize: false) {
                cell.customViewContainer.addSubview(routePickerView)
                routePickerView.anchorToAllSidesOf(view: cell.customViewContainer)

                cell.actionIcon.image = nil
            }

            if (action == .effects && PlaybackManager.shared.effects().effectsEnabled()) || (action == .sleepTimer && PlaybackManager.shared.sleepTimerActive()) || (action == .starEpisode && playingEpisode.keepEpisode) {
                cell.actionIcon.tintColor = PlayerColorHelper.playerHighlightColor01(for: .dark)
            } else {
                cell.actionIcon.tintColor = ThemeColor.playerContrast02()
            }
        } else {
            cell.actionName.text = action.title(episode: nil)
            cell.actionIcon.image = UIImage(named: action.iconName(episode: nil))
            cell.customViewContainer.removeAllSubviews()
            cell.actionIcon.tintColor = ThemeColor.playerContrast02()
        }

        cell.actionSubtitle.text = (tableView.isEditing && playingEpisode is UserEpisode) ? action.subtitle() : nil
        cell.actionSubtitle.isHidden = (cell.actionSubtitle.text == nil)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let action = actionAt(indexPath: indexPath, isEditing: tableView.isEditing)

        Analytics.track(.playerShelfActionTapped, properties: ["action": action.analyticsDescription, "from": "overflow_menu"])

        dismiss(animated: true) {
            guard action.isUnlocked else {
                action.paidFeature?.presentUpgradeController(from: self, source: "overflow_menu")
                return
            }

            switch action {
            case .starEpisode:
                self.playerActionsDelegate?.starEpisodeTapped()
            case .effects:
                self.playerActionsDelegate?.effectsTapped()
            case .sleepTimer:
                self.playerActionsDelegate?.sleepTimerTapped()
            case .routePicker:
                self.playerActionsDelegate?.routePickerTapped()
            case .shareEpisode:
                self.playerActionsDelegate?.shareTapped()
            case .goToPodcast:
                self.playerActionsDelegate?.goToTapped()
            case .chromecast:
                self.playerActionsDelegate?.chromecastTapped()
            case .markPlayed:
                self.playerActionsDelegate?.markPlayedTapped()
            case .archive:
                self.playerActionsDelegate?.archiveTapped()
            case .addBookmark:
                self.playerActionsDelegate?.bookmarkTapped()
            }
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rowsInShelfSection = tableView.numberOfRows(inSection: 0) // if you're moving out of the shortcuts section, the amount of items in there can change
        let fromRow = sourceIndexPath.row + (sourceIndexPath.section * Constants.Limits.maxShelfActions)
        let toRow = destinationIndexPath.row + (destinationIndexPath.section * rowsInShelfSection)

        let action = allActions.remove(at: fromRow)
        allActions.insert(action, at: toRow)
        Settings.updatePlayerActions(allActions)

        updateAvailableActions()

        let fromName = sourceIndexPath.section == 0 ? "shelf" : "overflow_menu"
        let toName = destinationIndexPath.section == 0 ? "shelf" : "overflow_menu"

        Analytics.track(.playerShelfOverflowMenuRearrangeActionMoved, properties: ["action": action.analyticsDescription, "moved_from": fromName, "moved_to": toName, "position": destinationIndexPath.row])

        // if someone has moved something into the shortcut section, move the bottom item out. Done async so that this method can return first
        if destinationIndexPath.section == ShelfActionsViewController.shortcutSection, sourceIndexPath.section != ShelfActionsViewController.shortcutSection {
            DispatchQueue.main.async {
                tableView.beginUpdates()
                tableView.moveRow(at: IndexPath(row: 4, section: ShelfActionsViewController.shortcutSection), to: IndexPath(row: 0, section: ShelfActionsViewController.menuSection))
                tableView.endUpdates()
            }
        }
        // another option is they could move something out of the shortcut section into the menu section, which also requires a re-shuffle
        else if destinationIndexPath.section == ShelfActionsViewController.menuSection, sourceIndexPath.section == ShelfActionsViewController.shortcutSection {
            DispatchQueue.main.async {
                tableView.beginUpdates()
                tableView.moveRow(at: IndexPath(row: 0, section: ShelfActionsViewController.menuSection), to: IndexPath(row: 3, section: ShelfActionsViewController.shortcutSection))
                tableView.endUpdates()
            }
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !tableView.isEditing { return nil }

        let headerFrame = CGRect(x: 0, y: 0, width: 0, height: Constants.Values.tableSectionHeaderHeight)
        let headerView: SettingsTableHeader
        if section == ShelfActionsViewController.shortcutSection {
            headerView = SettingsTableHeader(frame: headerFrame, title: L10n.playerOptionsShortcutOnPlayer)
        } else {
            headerView = SettingsTableHeader(frame: headerFrame, title: L10n.settingsInMenu)
        }
        headerView.titleLabel.style = .playerContrast02
        headerView.clearBackground = true

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        tableView.isEditing ? Constants.Values.tableSectionHeaderHeight : CGFloat.leastNonzeroMagnitude
    }

    private func actionAt(indexPath: IndexPath, isEditing: Bool) -> PlayerAction {
        let action: PlayerAction
        if isEditing {
            action = allActions[indexPath.row + (indexPath.section == ShelfActionsViewController.menuSection ? Constants.Limits.maxShelfActions : 0)]
        } else {
            action = extraActions[indexPath.row]
        }

        return action
    }
}
