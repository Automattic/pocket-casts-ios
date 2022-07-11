import Foundation

enum EpisodeAction: Identifiable {
    var id: Self { self }

    case download
    case pauseDownload
    case deleteDownload
    case removeFromQueue
    case playNext
    case playLast
    case archive
    case unarchive
    case star
    case unstar
    case markPlayed
    case markUnplayed
}

extension EpisodeAction {
    var title: String {
        switch self {
        case .download:
            return L10n.download
        case .pauseDownload:
            return L10n.stopDownload
        case .deleteDownload:
            return L10n.deleteDownload
        case .removeFromQueue:
            return L10n.removeUpNext
        case .playNext:
            return L10n.playNext
        case .playLast:
            return L10n.playLast
        case .archive:
            return L10n.archive
        case .unarchive:
            return L10n.unarchive
        case .star:
            return L10n.starEpisodeShort
        case .unstar:
            return L10n.unstar
        case .markPlayed:
            return L10n.markPlayedShort
        case .markUnplayed:
            return L10n.markUnplayedShort
        }
    }

    var iconName: String {
        switch self {
        case .download:
            return "episode_download"
        case .pauseDownload:
            return "episode_download_stop"
        case .deleteDownload:
            return "episode_delete"
        case .removeFromQueue:
            return "episode_upnext_remove"
        case .playNext:
            return "episode_playnext"
        case .playLast:
            return "episode_playlast"
        case .archive:
            return "episode_archive"
        case .unarchive:
            return "episode_unarchive"
        case .star:
            return "episode_star"
        case .unstar:
            return "episode_star_filled"
        case .markPlayed:
            return "episode_markplayed"
        case .markUnplayed:
            return "episode_markunplayed"
        }
    }

    var secondaryIconName: String {
        switch self {
        case .playNext:
            return "movetotop"
        case .playLast:
            return "movetobottom"
        default:
            return iconName
        }
    }

    var shouldDismiss: Bool {
        switch self {
        case .removeFromQueue, .playNext, .playLast, .archive, .markPlayed, .deleteDownload:
            return true
        default:
            return false
        }
    }
}

extension EpisodeAction {
    var confirmationTitle: String {
        switch self {
        case .deleteDownload:
            return L10n.deleteFile
        default:
            return ""
        }
    }

    var confirmationMessage: String {
        switch self {
        case .deleteDownload:
            return L10n.deleteFileMessage
        default:
            return ""
        }
    }

    var confirmationButtonTitle: String {
        switch self {
        case .deleteDownload:
            return L10n.delete
        default:
            return ""
        }
    }
}
