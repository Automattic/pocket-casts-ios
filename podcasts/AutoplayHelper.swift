import Foundation
import PocketCastsDataModel

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let topViewControllerGetter: TopViewControllerGetter
    private let userDefaultsKey = "playlist"
    private let episodesDataManager: EpisodesDataManager

    var lastPlaylist: EpisodesDataManager.Playlist? {
        if let rawDictionary = userDefaults.dictionary(forKey: userDefaultsKey),
           let dictData = try? JSONSerialization.data(withJSONObject: rawDictionary) {
            return try? JSONDecoder().decode(EpisodesDataManager.Playlist.self, from: dictData)
        }

        return nil
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         topViewControllerGetter: TopViewControllerGetter = UIApplication.shared,
         episodesDataManager: EpisodesDataManager = EpisodesDataManager()) {
        self.userDefaults = userDefaults
        self.topViewControllerGetter = topViewControllerGetter
        self.episodesDataManager = episodesDataManager
    }

    func savePlaylist() {
        #if !os(watchOS)
        let topViewController = topViewControllerGetter.getTopViewController() as? PlaylistAutoplay

        save(selectedPlaylist: topViewController?.playlist)
        #endif
    }

    /// Given the current episode UUID, checks if there's any
    /// episode to play.
    /// This is done by checking the list from the last place the user
    /// started playing it, locating the current episode there and
    /// returning the subsequent one.
    func nextEpisode(currentEpisodeUuid: String) -> BaseEpisode? {
        if let lastPlaylist = lastPlaylist {
            let playlistEpisodes = episodesDataManager.episodes(for: lastPlaylist)

            if let index = playlistEpisodes.firstIndex(where: { $0.uuid == currentEpisodeUuid }),
               let nextEpisode = playlistEpisodes[safe: index + 1] {
                return nextEpisode
            }
        }

        return nil
    }

    private func save(selectedPlaylist playlist: EpisodesDataManager.Playlist?) {
        guard let playlist else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            return
        }

        if let data = try? JSONEncoder().encode(playlist),
           let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
            userDefaults.set(dict, forKey: userDefaultsKey)
        }
    }
}

// MARK: - TopViewControllerGetter

protocol TopViewControllerGetter {
    func getTopViewController(base: UIViewController?) -> UIViewController?
}

extension TopViewControllerGetter {
    func getTopViewController(base: UIViewController? = SceneHelper.rootViewController()) -> UIViewController? {
        getTopViewController(base: base)
    }
}

extension UIApplication: TopViewControllerGetter { }
