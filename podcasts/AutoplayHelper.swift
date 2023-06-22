import Foundation

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "playlist"

    private init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func savePlaylist() {
        #if !os(watchOS)
        let topViewController = UIApplication.shared.getTopViewController() as? PlaylistAutoplay

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
