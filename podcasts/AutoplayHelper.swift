import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// Reponsible for handling the Autoplay of episodes
class AutoplayHelper {
    enum Playlist: Codable, AnalyticsDescribable {
        case podcast(uuid: String)
        case filter(uuid: String)
        case downloads
        case files
        case starred

        var analyticsDescription: String {
            switch self {
            case .podcast(uuid: _):
                return "podcast"
            case .filter(uuid: _):
                return "filter"
            case .downloads:
                return "downloads"
            case .files:
                return "files"
            case .starred:
                return "starred"
            }
        }
    }

    #if !os(watchOS)
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"
    private let episodesDataManager: EpisodesDataManager
    private let upNextQueue: PlaybackQueue

    /// Returns the latest playlist that the user played an episode from
    var lastPlaylist: Playlist? {
        let lastPlaylist = userDefaults.data(forKey: userDefaultsKey).flatMap {
            try? JSONDecoder().decode(Playlist.self, from: $0)
        }

        FileLog.shared.addMessage("Autoplay: returning the last playlist: \(String(describing: lastPlaylist))")

        return lastPlaylist
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         episodesDataManager: EpisodesDataManager = EpisodesDataManager(),
         queue: PlaybackQueue = PlaybackQueue()) {
        self.userDefaults = userDefaults
        self.episodesDataManager = episodesDataManager
        self.upNextQueue = queue
    }

    /// Saves the current playlist
    func playedFrom(playlist: Playlist?) {
        save(selectedPlaylist: playlist)

        // We always save the playlist no matter if Up Next is empty or not
        // However this event should be fired only if the Up Next is empty.
        if Settings.autoplay && upNextQueue.upNextCount() == 0 {
            Analytics.track(.autoplayStarted, properties: ["source": playlist ?? "unknown"])
        }
    }

    /// Given the current episode UUID, checks if there's any
    /// episode to play.
    /// This is done by checking the list from the last place the user
    /// started playing it, locating the current episode there and
    /// returning the subsequent one.
    func nextEpisode(currentEpisodeUuid: String) -> BaseEpisode? {
        if let lastPlaylist {
            let playlistEpisodes = episodesDataManager.episodes(for: lastPlaylist)

            if let index = playlistEpisodes.firstIndex(where: { $0.uuid == currentEpisodeUuid }) {
                return playlistEpisodes[safe: index + 1]
            }
        }

        return nil
    }

    private func save(selectedPlaylist playlist: Playlist?) {
        guard let playlist else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            FileLog.shared.addMessage("Autoplay: reset the last playlist")
            return
        }

        guard let data = try? JSONEncoder().encode(playlist) else {
            return
        }

        userDefaults.set(data, forKey: userDefaultsKey)
        FileLog.shared.addMessage("Autoplay: saving the latest playlist: \(playlist)")
    }
    #endif
}
