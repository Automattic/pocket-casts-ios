import Foundation
import PocketCastsDataModel

class ListPlaylist: ListItem, Identifiable, Hashable {
    let playlist: EpisodeFilter

    var id: String {
        playlist.uuid
    }

    override var differenceIdentifier: String {
        playlist.uuid
    }

    init(playlist: EpisodeFilter) {
        self.playlist = playlist
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ListPlaylist, rhs: ListPlaylist) -> Bool {
        lhs.handleIsEqual(rhs)
    }

    override func isContentEqual(to source: ListItem) -> Bool {
        handleIsEqual(source)
    }

    override func handleIsEqual(_ otherItem: ListItem) -> Bool {
        guard let rhs = otherItem as? ListPlaylist else { return false }

        return playlist.uuid == rhs.playlist.uuid &&
        playlist.playlistUpdateDate == rhs.playlist.playlistUpdateDate
    }
}
