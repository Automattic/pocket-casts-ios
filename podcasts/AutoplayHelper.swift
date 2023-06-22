import Foundation

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private init() { }

    func savePlaylist() {
        #if !os(watchOS)
        let topViewController = UIApplication.shared.getTopViewController() as? PlaylistAutoplay

        save(selectedPlaylist: topViewController?.playlist)
        #endif
    }

    private func save(selectedPlaylist: EpisodesDataManager.Playlist?) {

    }
}
