import UIKit

extension UIViewController {
    func longPressSelectOptions(
        for indexPath: IndexPath,
        in tableView: UITableView,
        firstSection: Int? = nil,
        lastSection: Int? = nil,
        themeOverride: Theme.ThemeType? = nil,
        statusBarStyle: UIStatusBarStyle? = nil,
        allAboveAction: ((Bool) -> Void)? = nil,
        allBelowAction: ((Bool) -> Void)? = nil
    ) {
        let allAboveAreSelected = tableView.allAboveAreSelected(indexPath: indexPath) == true
        let allBelowAreSelected = tableView.allBelowAreSelected(indexPath: indexPath) == true
        let optionPicker = OptionsPicker(title: nil, themeOverride: themeOverride, iconTintStyle: .primaryIcon02)

        let firstSectionIndex = firstSection ?? indexPath.section

        if indexPath != IndexPath(row: 0, section: firstSectionIndex) {
            let allAboveAction = OptionAction(
                label: allAboveAreSelected ? L10n.deselectAllAbove : L10n.selectAllAbove,
                icon: allAboveAreSelected ? "deselectall-up" : "selectall-up",
                action: { [] in
                    allAboveAction?(allAboveAreSelected)
                    if allAboveAreSelected {
                        tableView.deselectAllAbove(indexPath: indexPath)
                    } else {
                        tableView.selectAllAbove(indexPath: indexPath)
                    }
                })
            optionPicker.addAction(action: allAboveAction)
        }

        let lastSectionIndex = lastSection ?? indexPath.section
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1

        if indexPath != IndexPath(row: lastRowIndex, section: lastSectionIndex) {
            let allBelowAction = OptionAction(
                label: allBelowAreSelected ? L10n.deselectAllBelow : L10n.selectAllBelow,
                icon: allBelowAreSelected ? "deselectall-down" : "selectall-down",
                action: { [] in
                    allBelowAction?(allBelowAreSelected)
                    if allBelowAreSelected {
                        tableView.deselectAllBelow(indexPath: indexPath)
                    } else {
                        tableView.selectAllBelow(indexPath: indexPath)
                    }
            })
            optionPicker.addAction(action: allBelowAction)
        }

        optionPicker.show(statusBarStyle: statusBarStyle ?? preferredStatusBarStyle)
    }
}
