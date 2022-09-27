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

        func play() {
            track(.play)
        }

        func pause() {
            track(.pause)
        }

        func skipBack() {
            track(.skipBack)
        }

        func skipForward() {
            track(.skipForward)
        }

        private func track(_ event: AnalyticsEvent) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                Analytics.track(event, properties: ["source": self.currentPlaybackSource])
            }
        }

        private func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
            guard UIApplication.shared.applicationState == .active else {
                return nil
            }

            if let nav = base as? UINavigationController {
                return getTopViewController(base: nav.visibleViewController)
            } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(base: selected)
            } else if let presented = base?.presentedViewController {
                return getTopViewController(base: presented)
            }
            return base
        }
    #endif
}
