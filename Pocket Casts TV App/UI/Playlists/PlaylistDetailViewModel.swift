import SwiftUI
import Combine
import PocketCastsUtils

@Observable
class PlaylistDetailViewModel {

    private var cancellable: AnyCancellable?

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    let playlist: MockPlaylist

    init(playlist: MockPlaylist) {
        self.playlist = playlist
    }

    func load() {
        cancellable = Timer.publish(every: 1.0, on: .main, in: .common, options: nil)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                state = .ready
                cancellable?.cancel()
                cancellable = nil
            }
    }

    func playAll() {

    }

    var totalDuration: String {
        let total = playlist.episodes.reduce(0) { $0 + $1.duration }
        return TimeFormatter.shared.multipleUnitFormattedShortTime(time: total)
    }

    var episodeCountText: String {
        return L10n.tvPlaylistDetailEpisodeCount(playlist.episodes.count)
    }

    var coverImages: [String] {
        var seen = Set<String>()
        var unique = [String]()
        for episode in playlist.episodes {
            if seen.insert(episode.image).inserted {
                unique.append(episode.image)
            }
            if unique.count == 4 { break }
        }
        return unique
    }
}
