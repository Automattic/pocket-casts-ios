import Foundation
import SwipeCellKit

class TableSwipeActions {
    private var actions = [TableSwipeAction]()

    func addAction(_ action: TableSwipeAction) {
        actions.append(action)
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
    let handler: (IndexPath) -> Bool
}
