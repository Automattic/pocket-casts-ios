import Foundation
import PocketCastsDataModel

struct PlaylistItem: Identifiable, Equatable, Hashable {

    let playlist: EpisodeFilter

    var id: String {
        return playlist.uuid
    }

    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        return lhs.playlist.uuid == rhs.playlist.uuid &&
        lhs.playlist.playlistUpdateDate == rhs.playlist.playlistUpdateDate &&
        lhs.playlist.playlistName == rhs.playlist.playlistName
    }
}
