import Foundation

class AutoplayHelper {
    enum Playlist: Codable {
        case podcast(uuid: String)
        case filter(uuid: String)
        case downloads
        case files
        case starred
        case unknown
    }

    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"

    var lastPlaylist: Playlist? {
        userDefaults.data(forKey: userDefaultsKey).flatMap {
            try? JSONDecoder().decode(Playlist.self, from: $0)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func playedFrom(playlist: Playlist?) {
        #if !os(watchOS)
        save(selectedPlaylist: playlist)
        #endif
    }

    private func save(selectedPlaylist playlist: Playlist?) {
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
