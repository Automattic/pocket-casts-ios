import SwiftUI
import PocketCastsUtils
import PocketCastsDataModel
import PocketCastsServer

class BookmarkRowViewModel: ObservableObject {
    @Published var heading: String?
    let title: String
    let subtitle: String
    let playButton: String
    @Published var episode: BaseEpisode?

    init(bookmark: Bookmark) {
        self.episode = bookmark.episode
        self.title = bookmark.title
        self.playButton = TimeFormatter.shared.playTimeFormat(time: bookmark.time)
        self.subtitle = DateFormatter.localizedString(from: bookmark.created,
                                                      dateStyle: .medium,
                                                      timeStyle: .short)
        if let episode {
            updateFromEpisode(episode)
        } else {
            loadEpisode(from: bookmark)
        }
    }

    private func updateFromEpisode(_ episode: BaseEpisode) {
        self.episode = episode
        self.heading = episode.title
    }

    private func loadEpisode(from bookmark: Bookmark) {
        // Get the bookmark's BaseEpisode so we can load it
        let dataManager = DataManager.sharedManager
        if let episode = bookmark.episode ?? dataManager.findBaseEpisode(uuid: bookmark.episodeUuid) {
            updateFromEpisode(episode)
        }
        if let podcastUuid = bookmark.podcastUuid {
            ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: bookmark.episodeUuid, podcastUuid: podcastUuid) { [weak self] episode in
                if let episode {
                    DispatchQueue.main.async {
                        self?.updateFromEpisode(episode)
                    }
                }
            }
        }
    }
}
