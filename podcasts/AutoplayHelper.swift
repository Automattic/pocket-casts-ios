import Foundation

class AutoplayHelper {
    static let shared = AutoplayHelper()

    private init() { }

    func savePlaylist() {
        #if !os(watchOS)
        let topViewController = UIApplication.shared.getTopViewController() as? PlaylistAutoplay
        let source = topViewController?.playlist
        print("source: \(source)")
        #endif
    }
}
