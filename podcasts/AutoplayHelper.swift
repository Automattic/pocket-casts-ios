import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// Reponsible for handling the Autoplay of episodes
class AutoplayHelper {
    enum Playlist: Codable {
        case podcast(uuid: String)
        case filter(uuid: String)
        case downloads
        case files
        case starred
    }

    #if !os(watchOS)
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"
    private let episodesDataManager: EpisodesDataManager

    /// Returns the latest playlist that the user played an episode from
    var lastPlaylist: Playlist? {
        let lastPlaylist = userDefaults.data(forKey: userDefaultsKey).flatMap {
            try? JSONDecoder().decode(Playlist.self, from: $0)
        }

        FileLog.shared.addMessage("Autoplay: returning the last playlist: \(String(describing: lastPlaylist))")

        return lastPlaylist
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         episodesDataManager: EpisodesDataManager = EpisodesDataManager()) {
        self.userDefaults = userDefaults
        self.episodesDataManager = episodesDataManager
    }

    /// Saves the current playlist
    func playedFrom(playlist: Playlist?) {
        save(selectedPlaylist: playlist)
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
