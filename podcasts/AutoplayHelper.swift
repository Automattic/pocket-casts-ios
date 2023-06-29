import Foundation
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

    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"

    /// Returns the latest playlist that the user played an episode from
    var lastPlaylist: Playlist? {
        let lastPlaylist = userDefaults.data(forKey: userDefaultsKey).flatMap {
            try? JSONDecoder().decode(Playlist.self, from: $0)
        }

        FileLog.shared.addMessage("Autoplay: returning the last playlist: \(String(describing: lastPlaylist))")

        return lastPlaylist
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Saves the current playlist
    func playedFrom(playlist: Playlist?) {
        #if !os(watchOS)
        save(selectedPlaylist: playlist)
        #endif
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
