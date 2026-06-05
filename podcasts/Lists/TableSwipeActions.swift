import Foundation
import UIKit

class TableSwipeActions {
    private var actions = [TableSwipeAction]()

    func addAction(_ action: TableSwipeAction) {
        actions.append(action)
    }

    func addAction(_ action: TableSwipeAction, at index: Int) {
        actions.insert(action, at: index)
    }

    func swipeActions(performsFirstActionWithFullSwipe: Bool = true) -> UISwipeActionsConfiguration? {
        var swipeActions = [UIContextualAction]()
        for tableAction in actions {
            // All actions use the `.normal` style. `.destructive` would make the table view
            // auto-animate the row's removal on a full swipe, which conflicts with the handlers'
            // own list reloads and can crash; the handler stays the single source of truth for
            // removal (matching SwipeCellKit's `.destructive(automaticallyDelete: false)`).
            let convertedAction = UIContextualAction(style: .normal, title: nil, handler: { _, _, completionHandler in
                let completed = tableAction.handler(tableAction.indexPath)
                completionHandler(completed)
            })
            convertedAction.backgroundColor = tableAction.backgroundColor
            if let image = tableAction.icon {
                convertedAction.image = image
            }
            if let title = tableAction.title {
                convertedAction.accessibilityLabel = title
            }
            swipeActions.append(convertedAction)
        }

        let configuration = UISwipeActionsConfiguration(actions: swipeActions)
        configuration.performsFirstActionWithFullSwipe = performsFirstActionWithFullSwipe
        return configuration
    }
}

struct TableSwipeAction {
    let indexPath: IndexPath
    let title: String?
    let removesFromList: Bool
    let backgroundColor: UIColor
    let icon: UIImage?
    let tableView: UITableView
    let hidesWhenSelected: Bool
    let handler: (IndexPath) -> Bool

    init(
        indexPath: IndexPath,
        title: String?,
        removesFromList: Bool,
        backgroundColor: UIColor,
        icon: UIImage?,
        tableView: UITableView,
        hidesWhenSelected: Bool = false,
        handler: @escaping (IndexPath) -> Bool
    ) {
        self.indexPath = indexPath
        self.title = title
        self.removesFromList = removesFromList
        self.backgroundColor = backgroundColor
        self.icon = icon
        self.tableView = tableView
        self.hidesWhenSelected = hidesWhenSelected
        self.handler = handler
    }
}
