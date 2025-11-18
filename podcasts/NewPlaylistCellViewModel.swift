import SwiftUI
import PocketCastsDataModel

#if canImport(UIKit)
import UIKit
#endif

class NewPlaylistCellViewModel: ObservableObject {
    enum DisplayType {
        case count
        case toggle
        case check
        case addNew
        case plain
    }

    @Published var episodesCount: Int = 0
    @Published var images: [PlaylistArtworkView.ImageItem] = []
    @Published var playlistName: String = ""
    @Published var isSmartPlaylist: Bool = false
    @Published var displayType: DisplayType = .count

    var isBelowEpisodeLimit: Bool {
#if DEBUG
        episodesCount < Settings.debugPlaylistsLimit
#else
        episodesCount < Constants.Limits.maxFilterItems
#endif
    }
}
