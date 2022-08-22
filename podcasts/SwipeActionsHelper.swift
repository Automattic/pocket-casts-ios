import Foundation
import PocketCastsDataModel

protocol SwipeHandler: AnyObject {
    func archivingRemovesFromList() -> Bool
    func actionPerformed(willBeRemoved: Bool)
    func deleteRequested(uuid: String)
}

enum SwipeActionsHelper {
    static func createLeftActionsForEpisode(_ episode: BaseEpisode, tableView: UITableView, indexPath: IndexPath, swipeHandler: SwipeHandler) -> TableSwipeActions {
        let tableSwipeActions = TableSwipeActions()
        let storedUuid = episode.uuid
        
        if PlaybackManager.shared.inUpNext(episode: episode) {
            let removeFromUpNextAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.removeFromUpNext, removesFromList: false, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "episode-removenext"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.removeIfPlayingOrQueued(episode: loadedEpisode, fireNotification: true)
                    swipeHandler.actionPerformed(willBeRemoved: false)
                }
                
                return true
            })
            tableSwipeActions.addAction(removeFromUpNextAction)
        }
        else {
            let addTopAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.playNext, removesFromList: false, backgroundColor: ThemeColor.support04(), icon: UIImage(named: "list_playnext"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.addToUpNext(episode: loadedEpisode, ignoringQueueLimit: true, toTop: true)
                    swipeHandler.actionPerformed(willBeRemoved: false)
                }
                
                return true
            })
            
            let addBottomAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.playLast, removesFromList: false, backgroundColor: ThemeColor.support03(), icon: UIImage(named: "list_playlast"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.addToUpNext(episode: loadedEpisode, ignoringQueueLimit: true, toTop: false)
                    swipeHandler.actionPerformed(willBeRemoved: false)
                }
                
                return true
            })
            
            if Settings.primaryUpNextSwipeAction() == .playNext {
                tableSwipeActions.addAction(addTopAction)
                tableSwipeActions.addAction(addBottomAction)
            }
            else {
                tableSwipeActions.addAction(addBottomAction)
                tableSwipeActions.addAction(addTopAction)
            }
        }
        
        return tableSwipeActions
    }
    
    static func createRightActionsForEpisode(_ episode: BaseEpisode, tableView: UITableView, indexPath: IndexPath, swipeHandler: SwipeHandler) -> TableSwipeActions {
        let tableSwipeActions = TableSwipeActions()
        let storedUuid = episode.uuid
        
        if episode is UserEpisode {
            let deleteAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.delete, removesFromList: false, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "delete"), tableView: tableView, handler: { _ -> Bool in
                swipeHandler.deleteRequested(uuid: storedUuid)
                
                return true
            })
            tableSwipeActions.addAction(deleteAction)
        }
        else if episode.archived {
            let willBeRemoved = false
            let unarchiveAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.unarchive, removesFromList: willBeRemoved, backgroundColor: ThemeColor.support06(), icon: UIImage(named: "list_unarchive"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findEpisode(uuid: storedUuid) {
                    EpisodeManager.unarchiveEpisode(episode: loadedEpisode, fireNotification: false)
                    swipeHandler.actionPerformed(willBeRemoved: willBeRemoved)
                }
                
                return true
            })
            tableSwipeActions.addAction(unarchiveAction)
        }
        else {
            let willBeRemoved = swipeHandler.archivingRemovesFromList()
            let archiveAction = TableSwipeAction(indexPath: indexPath, title: L10n.Localizable.archive, removesFromList: willBeRemoved, backgroundColor: ThemeColor.support06(), icon: UIImage(named: "list_archive"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findEpisode(uuid: storedUuid) {
                    EpisodeManager.archiveEpisode(episode: loadedEpisode, fireNotification: false)
                    swipeHandler.actionPerformed(willBeRemoved: willBeRemoved)
                }
                
                return true
            })
            tableSwipeActions.addAction(archiveAction)
        }
        
        return tableSwipeActions
    }
}
