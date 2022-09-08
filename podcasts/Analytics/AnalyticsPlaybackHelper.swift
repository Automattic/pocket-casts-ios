import UIKit

protocol PlaybackSource {
    /// Used for analytics purpose when playing/pausing
    var playbackSource: String { get }
}

/// Helper used to track playback
class AnalyticsPlaybackHelper {
    static var shared = AnalyticsPlaybackHelper()

    /// Sometimes the playback source can't be inferred, just inform it here
    var currentSource: String?

    private init() {}

    #if !os(watchOS)
        private var currentPlaybackSource: String {
            if let currentSource = currentSource {
                self.currentSource = nil
                return currentSource
            }

            return (getTopViewController() as? PlaybackSource)?.playbackSource ?? "unknown"
        }

        private var informedSource: String {
            let informedSource = currentSource ?? "unknown"
            currentSource = nil
            return informedSource
        }

        func play() {
            track(.play, source: currentPlaybackSource)
        }

        func pause() {
            track(.pause, source: currentPlaybackSource)
        }

        func skipBack() {
            track(.play, source: informedSource)
        }

        func skipForward() {
            track(.play, source: informedSource)
        }

        private func track(_ event: AnalyticsEvent, source: String) {
            DispatchQueue.main.async {
                Analytics.track(event, properties: ["source": source])
            }
        }

        private func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return getTopViewController(base: nav.visibleViewController)
            }
            else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            }
            else if let presented = base?.presentedViewController {
                return getTopViewController(base: presented)
            }
            return base
        }
    #endif
}
