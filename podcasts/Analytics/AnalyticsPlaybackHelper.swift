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
        var currentPlaybackSource: String {
            if let currentSource = currentSource {
                self.currentSource = nil
                return currentSource
            }

            return (getTopViewController() as? PlaybackSource)?.playbackSource ?? "unknown"
        }

        var informedSource: String {
            let informedSource = currentSource ?? "unknown"
            currentSource = nil
            return informedSource
        }

        func play() {
            Analytics.track(.play, properties: ["source": currentPlaybackSource])
        }

        func pause() {
            Analytics.track(.pause, properties: ["source": currentPlaybackSource])
        }

        func skipBack() {
            Analytics.track(.skipBack, properties: ["source": informedSource])
        }

        func skipForward() {
            Analytics.track(.skipForward, properties: ["source": informedSource])
        }

        func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
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
