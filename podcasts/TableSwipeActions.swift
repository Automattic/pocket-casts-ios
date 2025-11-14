import Foundation
import SwipeCellKit

class TableSwipeActions {
    private var actions = [TableSwipeAction]()

    func addAction(_ action: TableSwipeAction) {
        actions.append(action)
    }

    func addAction(_ action: TableSwipeAction, at index: Int) {
        actions.insert(action, at: index)
    }

    func swipeActions() -> UISwipeActionsConfiguration? {
        var swipeActions = [UIContextualAction]()
        for tableAction in actions {
            let style = tableAction.removesFromList ? UIContextualAction.Style.destructive : UIContextualAction.Style.normal
            let convertedAction = UIContextualAction(style: style, title: nil, handler: { _, _, completionHandler in
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

        return UISwipeActionsConfiguration(actions: swipeActions)
    }

    func swipeKitActions() -> [SwipeAction] {
        var swipeActions = [SwipeAction]()
        for tableAction in actions {
            let style: SwipeActionStyle = tableAction.removesFromList ? .destructive : .default
            let swipeAction = SwipeAction(style: style, title: nil) { _, indexPath in
                _ = tableAction.handler(indexPath)
            }
            swipeAction.backgroundColor = tableAction.backgroundColor
            if let image = tableAction.icon {
                swipeAction.image = image
            }
            swipeAction.hidesWhenSelected = tableAction.hidesWhenSelected
            swipeAction.accessibilityLabel = tableAction.title
            swipeActions.append(swipeAction)
        }

        return swipeActions
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
