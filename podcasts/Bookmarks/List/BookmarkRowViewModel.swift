import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel
import PocketCastsServer

@MainActor
class BookmarkRowViewModel: ObservableObject {
    @Published private(set) var heading: String?
    @Published private(set) var episode: BaseEpisode?

    private var episodeUuid: String?

    /// Loads the bookmark's episode so the row can display its title and artwork
    func configure(with bookmark: Bookmark) async {
        guard episodeUuid != bookmark.episodeUuid else { return }
        episodeUuid = bookmark.episodeUuid

        let episode = await Self.loadEpisode(for: bookmark)

        if Task.isCancelled {
            // Let the next appearance retry the interrupted load
            if episodeUuid == bookmark.episodeUuid {
                episodeUuid = nil
            }
            return
        }

        if let episode {
            self.episode = episode
            self.heading = episode.title
        }
    }

    @concurrent
    nonisolated private static func loadEpisode(for bookmark: Bookmark) async -> BaseEpisode? {
        if let episode = bookmark.episode ?? DataManager.sharedManager.findBaseEpisode(uuid: bookmark.episodeUuid) {
            return episode
        }

        guard let podcastUuid = bookmark.podcastUuid else {
            return nil
        }

        return try? await ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: bookmark.episodeUuid, podcastUuid: podcastUuid)
    }
}
