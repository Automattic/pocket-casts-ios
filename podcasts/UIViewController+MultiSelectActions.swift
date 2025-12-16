import UIKit

extension UIViewController {
    func longPressSelectOptions(
        for indexPath: IndexPath,
        in tableView: UITableView,
        firstSection: Int? = nil,
        lastSection: Int? = nil,
        themeOverride: Theme.ThemeType? = nil,
        statusBarStyle: UIStatusBarStyle? = nil,
        excludingCellTypes: [UITableViewCell.Type]? = nil,
        allAboveAction: ((Bool) -> Void)? = nil,
        allBelowAction: ((Bool) -> Void)? = nil
    ) {
        guard let firstIndexPath = tableView.firstIndexPath(
            section: firstSection ?? indexPath.section,
            excludingCellTypes: excludingCellTypes
        ) else { return }

        let lastSectionIndex = lastSection ?? indexPath.section
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
        let lastIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)

        let allAboveAreSelected = tableView.allAboveAreSelected(fromIndexPath: firstIndexPath, to: indexPath) == true
        let allBelowAreSelected = tableView.allBelowAreSelected(indexPath: indexPath) == true

        let optionPicker = OptionsPicker(title: nil, themeOverride: themeOverride, iconTintStyle: .primaryIcon02)

        if indexPath != firstIndexPath {
            let allAboveAction = OptionAction(
                label: allAboveAreSelected ? L10n.deselectAllAbove : L10n.selectAllAbove,
                icon: allAboveAreSelected ? "deselectall-up" : "selectall-up",
                action: { [] in
                    allAboveAction?(allAboveAreSelected)
                    if allAboveAreSelected {
                        tableView.deselectAllAbove(
                            fromIndexPath: firstIndexPath,
                            to: indexPath
                        )
                    } else {
                        tableView.selectAllAbove(
                            fromIndexPath: firstIndexPath,
                            to: indexPath
                        )
                    }
                })
            optionPicker.addAction(action: allAboveAction)
        }

        if indexPath != lastIndexPath {
            let allBelowAction = OptionAction(
                label: allBelowAreSelected ? L10n.deselectAllBelow : L10n.selectAllBelow,
                icon: allBelowAreSelected ? "deselectall-down" : "selectall-down",
                action: { [] in
                    allBelowAction?(allBelowAreSelected)
                    if allBelowAreSelected {
                        tableView.deselectAllBelow(indexPath: indexPath)
                    } else {
                        tableView.selectAllBelow(fromIndexPath: indexPath)
                    }
            })
            optionPicker.addAction(action: allBelowAction)
        }

        optionPicker.show(statusBarStyle: statusBarStyle ?? preferredStatusBarStyle)
    }
}
