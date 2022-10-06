import Foundation

protocol AnalyticsSource {
    /// Used for analytics purpose when playing/pausing
    var playbackSource: String { get }
}

class AnalyticsCoordinator {
    /// Sometimes the playback source can't be inferred, just inform it here
    var currentSource: String?

    #if !os(watchOS)
        var currentAnalyticsSource: String {
            if let currentSource = currentSource {
                self.currentSource = nil
                return currentSource
            }

            return (getTopViewController() as? AnalyticsSource)?.playbackSource ?? "unknown"
        }

        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                let defaultProperties: [String: Any] = ["source": self.currentAnalyticsSource]
                let mergedProperties = defaultProperties.merging(properties ?? [:]) { current, _ in current }
                Analytics.track(event, properties: mergedProperties)
            }
        }

        func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
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
    #else
        /// NOOP track event to preventing needing to wrap all the events in #if checks
        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {}
    #endif
}
