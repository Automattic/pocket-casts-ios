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
            return L10n.Localizable.download
        case .pauseDownload:
            return L10n.Localizable.stopDownload
        case .deleteDownload:
            return L10n.Localizable.deleteDownload
        case .removeFromQueue:
            return L10n.Localizable.removeUpNext
        case .playNext:
            return L10n.Localizable.playNext
        case .playLast:
            return L10n.Localizable.playLast
        case .archive:
            return L10n.Localizable.archive
        case .unarchive:
            return L10n.Localizable.unarchive
        case .star:
            return L10n.Localizable.starEpisodeShort
        case .unstar:
            return L10n.Localizable.unstar
        case .markPlayed:
            return L10n.Localizable.markPlayedShort
        case .markUnplayed:
            return L10n.Localizable.markUnplayedShort
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
            return L10n.Localizable.deleteFile
        default:
            return ""
        }
    }

    var confirmationMessage: String {
        switch self {
        case .deleteDownload:
            return L10n.Localizable.deleteFileMessage
        default:
            return ""
        }
    }

    var confirmationButtonTitle: String {
        switch self {
        case .deleteDownload:
            return L10n.Localizable.delete
        default:
            return ""
        }
    }
}
