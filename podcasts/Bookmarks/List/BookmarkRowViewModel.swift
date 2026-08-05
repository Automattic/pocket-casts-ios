import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel
import PocketCastsServer

@MainActor @Observable
final class BookmarkRowViewModel {
    private(set) var episode: BaseEpisode?

    var heading: String? {
        episode?.title
    }

    private var episodeUuid: String?

    /// The lists that already load the episodes attach them to their bookmarks, so the row can
    /// display one straight away instead of waiting for the load
    init(bookmark: Bookmark) {
        self.episode = bookmark.episode
    }

    /// Loads the bookmark's episode so the row can display its title and artwork
    func configure(with bookmark: Bookmark) async {
        if let episode = bookmark.episode {
            self.episode = episode
            return
        }

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
        }
    }

    @concurrent
    nonisolated private static func loadEpisode(for bookmark: Bookmark) async -> BaseEpisode? {
        if let episode = DataManager.sharedManager.findBaseEpisode(uuid: bookmark.episodeUuid) {
            return episode
        }

        guard let podcastUuid = bookmark.podcastUuid else {
            return nil
        }

        return try? await ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: bookmark.episodeUuid, podcastUuid: podcastUuid)
    }
}
