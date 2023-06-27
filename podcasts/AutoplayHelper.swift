import Foundation

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"

    var lastPlaylist: EpisodesDataManager.Playlist? {
        userDefaults.data(forKey: userDefaultsKey).flatMap {
            try? JSONDecoder().decode(EpisodesDataManager.Playlist.self, from: $0)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func playedFrom(playlist: EpisodesDataManager.Playlist?) {
        #if !os(watchOS)
        save(selectedPlaylist: playlist)
        #endif
    }

    private func save(selectedPlaylist playlist: EpisodesDataManager.Playlist?) {
        guard let playlist else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            return
        }

        guard let data = try? JSONEncoder().encode(playlist) else {
            return
        }

        userDefaults.set(data, forKey: userDefaultsKey)
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
