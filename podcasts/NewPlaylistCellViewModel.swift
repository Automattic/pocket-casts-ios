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

    var isBelowEpisodeLimit: Bool {
#if DEBUG
        episodesCount < Settings.debugPlaylistsLimit
#else
        episodesCount < Constants.Limits.maxFilterItems
#endif
    }

    private var playlist: EpisodeFilter

    let displayType: DisplayType

    init(
        playlist: EpisodeFilter,
        displayType: DisplayType,
        episodesCount: Int,
        images: [PlaylistArtworkView.ImageItem]
    ) {
        self.playlist = playlist
        self.displayType = displayType
        self.images = images
        self.episodesCount = episodesCount
    }

    func playListName() -> String {
        playlist.playlistName
    }

    func isSmartPlaylist() -> Bool {
        playlist.manual == false
    }
}
