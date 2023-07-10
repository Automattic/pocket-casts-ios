import Foundation
import PocketCastsDataModel

protocol SwipeHandler: AnyObject {
    var swipeSource: String { get }

    func archivingRemovesFromList() -> Bool
    func actionPerformed(willBeRemoved: Bool)
    func deleteRequested(uuid: String)
    func share(episode: Episode, in: IndexPath)
}

enum SwipeActionsHelper {
    static func createLeftActionsForEpisode(_ episode: BaseEpisode, tableView: UITableView, indexPath: IndexPath, swipeHandler: SwipeHandler) -> TableSwipeActions {
        let tableSwipeActions = TableSwipeActions()
        let storedUuid = episode.uuid

        if PlaybackManager.shared.inUpNext(episode: episode) {
            let removeFromUpNextAction = TableSwipeAction(indexPath: indexPath, title: L10n.removeFromUpNext, removesFromList: false, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "episode-removenext"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.removeIfPlayingOrQueued(episode: loadedEpisode, fireNotification: true, userInitiated: true)
                    Self.performAction(.upNextRemove, handler: swipeHandler, willBeRemoved: false)
                }

                return true
            })
            tableSwipeActions.addAction(removeFromUpNextAction)
        } else {
            let addTopAction = TableSwipeAction(indexPath: indexPath, title: L10n.playNext, removesFromList: false, backgroundColor: ThemeColor.support04(), icon: UIImage(named: "list_playnext"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.addToUpNext(episode: loadedEpisode, ignoringQueueLimit: true, toTop: true, userInitiated: true)
                    Self.performAction(.upNextAddTop, handler: swipeHandler, willBeRemoved: false)
                }

                return true
            })

            let addBottomAction = TableSwipeAction(indexPath: indexPath, title: L10n.playLast, removesFromList: false, backgroundColor: ThemeColor.support03(), icon: UIImage(named: "list_playlast"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findBaseEpisode(uuid: storedUuid) {
                    PlaybackManager.shared.addToUpNext(episode: loadedEpisode, ignoringQueueLimit: true, toTop: false, userInitiated: true)
                    Self.performAction(.upNextAddBottom, handler: swipeHandler, willBeRemoved: false)
                }

                return true
            })

            if Settings.primaryUpNextSwipeAction() == .playNext {
                tableSwipeActions.addAction(addTopAction)
                tableSwipeActions.addAction(addBottomAction)
            } else {
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
            let deleteAction = TableSwipeAction(indexPath: indexPath, title: L10n.delete, removesFromList: false, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "delete"), tableView: tableView, handler: { _ -> Bool in
                swipeHandler.deleteRequested(uuid: storedUuid)
                Self.performAction(.delete, handler: swipeHandler, willBeRemoved: true)
                return true
            })
            tableSwipeActions.addAction(deleteAction)
        } else if episode.archived {
            let willBeRemoved = false
            let unarchiveAction = TableSwipeAction(indexPath: indexPath, title: L10n.unarchive, removesFromList: willBeRemoved, backgroundColor: ThemeColor.support06(), icon: UIImage(named: "list_unarchive"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findEpisode(uuid: storedUuid) {
                    EpisodeManager.unarchiveEpisode(episode: loadedEpisode, fireNotification: false)
                    Self.performAction(.unarchive, handler: swipeHandler, willBeRemoved: willBeRemoved)
                }

                return true
            })
            tableSwipeActions.addAction(unarchiveAction)
        } else {
            let willBeRemoved = swipeHandler.archivingRemovesFromList()
            let archiveAction = TableSwipeAction(indexPath: indexPath, title: L10n.archive, removesFromList: willBeRemoved, backgroundColor: ThemeColor.support06(), icon: UIImage(named: "list_archive"), tableView: tableView, handler: { _ -> Bool in
                if let loadedEpisode = DataManager.sharedManager.findEpisode(uuid: storedUuid) {
                    EpisodeManager.archiveEpisode(episode: loadedEpisode, fireNotification: false)
                    Self.performAction(.archive, handler: swipeHandler, willBeRemoved: willBeRemoved)
                }

                return true
            })
            tableSwipeActions.addAction(archiveAction)
        }

        if let episode = episode as? Episode {
            let shareAction = TableSwipeAction(indexPath: indexPath, title: L10n.share, removesFromList: false, backgroundColor: ThemeColor.support03(), icon: UIImage(named: "podcast-share"), tableView: tableView, handler: { indexPath -> Bool in
                    swipeHandler.share(episode: episode, in: indexPath)
                    Self.performAction(.share, handler: swipeHandler, willBeRemoved: false)
                return true
            })
            tableSwipeActions.addAction(shareAction)
        }

        return tableSwipeActions
    }

    private static func performAction(_ action: SwipeActions, handler: SwipeHandler, willBeRemoved: Bool) {
        let source = handler.swipeSource
        Analytics.track(.episodeSwipeActionPerformed, properties: ["action": action, "source": source])

        guard action != .delete else {
            return
        }

        handler.actionPerformed(willBeRemoved: willBeRemoved)
    }

    private enum SwipeActions: String, AnalyticsDescribable {
        case upNextRemove
        case upNextAddTop
        case upNextAddBottom
        case delete
        case unarchive
        case archive
        case share

        var analyticsDescription: String {
            switch self {
            case .upNextRemove:
                return "up_next_remove"
            case .upNextAddTop:
                return "up_next_add_top"
            case .upNextAddBottom:
                return "up_next_add_bottom"
            case .delete:
                return "delete"
            case .unarchive:
                return "unarchive"
            case .archive:
                return "archive"
            case .share:
                return "share"
            }
        }
    }
}
