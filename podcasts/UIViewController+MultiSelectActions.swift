import UIKit

extension UIViewController {
    func longPressSelectOptions(
        for indexPath: IndexPath,
        in tableView: UITableView,
        themeOverride: Theme.ThemeType? = nil,
        statusBarStyle: UIStatusBarStyle? = nil,
        allAboveAction: ((Bool) -> Void)? = nil,
        allBelowAction: ((Bool) -> Void)? = nil
    ) {
        let allAboveAreSelected = tableView.allAboveAreSelected(indexPath: indexPath) == true
        let allBelowAreSelected = tableView.allBelowAreSelected(indexPath: indexPath) == true

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

        let optionPicker = OptionsPicker(title: nil, themeOverride: themeOverride, iconTintStyle: .primaryIcon02)
        optionPicker.addAction(action: allAboveAction)
        optionPicker.addAction(action: allBelowAction)
        optionPicker.show(statusBarStyle: statusBarStyle ?? preferredStatusBarStyle)
    }
}
