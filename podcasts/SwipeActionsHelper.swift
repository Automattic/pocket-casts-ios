import Foundation
import PocketCastsDataModel
import PocketCastsUtils

enum SwipeSourceType {
    case podcast
    case smartPlaylistDetail
    case manualPlaylistDetail
    case filter
    case downloads
    case starred
    case listeningHistory
    case uploaded

    var canAddEpisodeToManualPlaylist: Bool {
        switch self {
        case .filter, .uploaded, .manualPlaylistDetail:
            false
        default:
            true
        }
    }

    var canRemoveEpisodeFromManualPlaylist: Bool {
        switch self {
        case .manualPlaylistDetail:
            true
        default:
            false
        }
    }
}

protocol SwipeHandler: AnyObject {
    var swipeSource: String { get }
    var swipeSourceType: SwipeSourceType { get }

    func archivingRemovesFromList() -> Bool
    func actionPerformed(willBeRemoved: Bool)
    func deleteRequested(uuid: String)
    func share(episode: Episode, at: IndexPath)
    func addToManualPlaylist(episode: Episode, at: IndexPath)
    func removeFromManualPlaylist(episode: Episode, at: IndexPath)
}

enum SwipeActionsHelper {
    static func createLeftActionsForEpisode(_ episode: BaseEpisode, tableView: UITableView, indexPath: IndexPath, swipeHandler: SwipeHandler) -> TableSwipeActions {
        let tableSwipeActions = TableSwipeActions()
        let storedUuid = episode.uuid

        if episode.wasDeleted {
            return tableSwipeActions // Should be empty
        }

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

        if let episode = episode as? Episode, FeatureFlag.playlistsRebranding.enabled && episode.wasDeleted && swipeHandler.swipeSourceType.canRemoveEpisodeFromManualPlaylist {
            tableSwipeActions.addAction(TableSwipeAction.removeAction(indexPath: indexPath, tableView: tableView, swipeHandler: swipeHandler, episode: episode), at: 0)
            return tableSwipeActions // Only include delete
        } else if episode is UserEpisode {
            let deleteAction = TableSwipeAction(indexPath: indexPath, title: L10n.delete, removesFromList: false, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "delete"), tableView: tableView, handler: { _ -> Bool in
                swipeHandler.deleteRequested(uuid: storedUuid)
                Self.performAction(.delete, handler: swipeHandler, willBeRemoved: true)
                return true
            })
            tableSwipeActions.addAction(deleteAction)
            return tableSwipeActions
        } else if episode.archived {
            let willBeRemoved = FeatureFlag.playlistsRebranding.enabled
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
                    swipeHandler.share(episode: episode, at: indexPath)
                    Self.performAction(.share, handler: swipeHandler, willBeRemoved: false)
                return true
            })
            tableSwipeActions.addAction(shareAction)

            if FeatureFlag.playlistsRebranding.enabled {
                if swipeHandler.swipeSourceType.canAddEpisodeToManualPlaylist {
                    let shareAction = TableSwipeAction(indexPath: indexPath, title: L10n.playlistManualAddEpisodes, removesFromList: false, backgroundColor: ThemeColor.support02(), icon: UIImage(named: "playlist-add-episode"), tableView: tableView, handler: { indexPath -> Bool in
                        swipeHandler.addToManualPlaylist(episode: episode, at: indexPath)
                        Self.performAction(.addToManualPlaylist, handler: swipeHandler, willBeRemoved: false)
                        return true
                    })
                    tableSwipeActions.addAction(shareAction)
                }

                if swipeHandler.swipeSourceType.canRemoveEpisodeFromManualPlaylist {
                    tableSwipeActions.addAction(TableSwipeAction.removeAction(indexPath: indexPath, tableView: tableView, swipeHandler: swipeHandler, episode: episode), at: 0)
                }
            }
        }

        return tableSwipeActions
    }

    fileprivate static func performAction(_ action: SwipeActions, handler: SwipeHandler, willBeRemoved: Bool) {
        let source = handler.swipeSource
        var properties = ["action": action, "source": source] as [String: Any]
        if FeatureFlag.playlistsRebranding.enabled {
            let playlistSourceType = switch handler.swipeSourceType {
            case .manualPlaylistDetail:
                "manual"
            case .smartPlaylistDetail:
                "smart"
            default:
                ""
            }
            if !playlistSourceType.isEmpty {
                properties["filter_type"] = playlistSourceType
            }
        }
        Analytics.track(.episodeSwipeActionPerformed, properties: properties)

        guard action != .delete else {
            return
        }

        handler.actionPerformed(willBeRemoved: willBeRemoved)
    }

    fileprivate enum SwipeActions: String, AnalyticsDescribable {
        case upNextRemove
        case upNextAddTop
        case upNextAddBottom
        case delete
        case unarchive
        case archive
        case share
        case addToManualPlaylist
        case removeFromManualPlaylist

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
            case .addToManualPlaylist:
                return "add_to_playlist"
            case .removeFromManualPlaylist:
                return "remove_from_playlist"
            }
        }
    }
}

fileprivate extension TableSwipeAction {
    static func removeAction(indexPath: IndexPath, tableView: UITableView, swipeHandler: SwipeHandler, episode: Episode) -> TableSwipeAction {
        return TableSwipeAction(indexPath: indexPath, title: L10n.delete, removesFromList: true, backgroundColor: ThemeColor.support05(), icon: UIImage(named: "delete"), tableView: tableView, handler: { _ -> Bool in
            swipeHandler.removeFromManualPlaylist(episode: episode, at: indexPath)
            SwipeActionsHelper.performAction(.removeFromManualPlaylist, handler: swipeHandler, willBeRemoved: false)
            return true
        })
    }
}
