import PocketCastsDataModel
import WatchKit

protocol PlaylistRepresentable {
    var uuid: String { get }
    var title: String { get }
    var iconName: String? { get }
}

class WatchPlaylist: Equatable, PlaylistRepresentable {
    var title = ""
    var uuid = ""
    var iconName: String? = ""

    static func == (lhs: WatchPlaylist, rhs: WatchPlaylist) -> Bool {
        lhs.title == rhs.title && lhs.uuid == rhs.uuid && lhs.iconName == rhs.iconName
    }
}

extension EpisodeFilter: PlaylistRepresentable {
    var title: String {
        playlistName
    }

    var iconName: String? {
        iconImageName()
    }
}
