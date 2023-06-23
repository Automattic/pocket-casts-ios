import Foundation

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let topViewControllerGetter: TopViewControllerGetter
    private let userDefaultsKey = "playlist"

    var lastPlaylist: EpisodesDataManager.Playlist? {
        if let rawDictionary = userDefaults.dictionary(forKey: userDefaultsKey),
           let dictData = try? JSONSerialization.data(withJSONObject: rawDictionary) {
            return try? JSONDecoder().decode(EpisodesDataManager.Playlist.self, from: dictData)
        }

        return nil
    }

    init(userDefaults: UserDefaults = UserDefaults.standard,
         topViewControllerGetter: TopViewControllerGetter = UIApplication.shared) {
        self.userDefaults = userDefaults
        self.topViewControllerGetter = topViewControllerGetter
    }

    func savePlaylist() {
        #if !os(watchOS)
        let topViewController = topViewControllerGetter.getTopViewController() as? PlaylistAutoplay

        save(selectedPlaylist: topViewController?.playlist)
        #endif
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
