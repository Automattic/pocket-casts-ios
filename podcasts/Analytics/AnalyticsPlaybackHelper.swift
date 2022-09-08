import UIKit

protocol PlaybackSource {
    /// Used for analytics purpose when playing/pausing
    var playbackSource: String { get }
}

/// Helper used to track playback
class AnalyticsPlaybackHelper {
    #if !os(watchOS)
    func play() {
        let playBackSource = (getTopViewController() as? PlaybackSource)?.playbackSource ?? "unknown"
        Analytics.track(.play, properties: ["source": playBackSource])
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
