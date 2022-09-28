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

    /// Whether to ignore the next seek event
    private var ignoreNextSeek = false

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
            track(.playbackPlay)
        }

        func pause() {
            track(.playbackPause)
        }

        func skipBack() {
            ignoreNextSeek = true
            track(.playbackSkipBack)
        }

        func skipForward() {
            ignoreNextSeek = true
            track(.playbackSkipForward)
        }

        func seek(from: TimeInterval, to: TimeInterval, duration: TimeInterval) {
            // Currently ignore a seek event that is triggered by a sync process
            // Using the skip buttons triggers a seek, ignore this as well
            guard currentSource != "sync", ignoreNextSeek == false else {
                ignoreNextSeek = false
                return
            }

            // Use percents to relativize the seeking across any duration episode
            let seekFrom = Int((from / duration) * 100)
            let seekPercent = Int((to / duration) * 100)

            track(.playbackSeek, properties: ["seek_to_percent": seekPercent, "seek_from_percent": seekFrom])
        }

        func playbackSpeedChanged(to speed: Double) {
            track(.playbackEffectSpeedChanged, properties: ["speed": speed])
        }

        func trimSilenceToggled(enabled: Bool) {
            track(.playbackEffectTrimSilenceToggled, properties: ["enabled": enabled])
        }

        func trimSilenceAmountChanged(amount: TrimSilenceAmount) {
            track(.playbackEffectTrimSilenceAmountChanged, properties: ["amount": amount.analyticsDescription])
        }

        func volumeBoostToggled(enabled: Bool) {
            track(.playbackEffectVolumeBoostToggled, properties: ["enabled": enabled])
        }

    #endif
}

private extension AnalyticsPlaybackHelper {
    #if !os(watchOS)
        func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
            
                let defaultProperties: [String: Any] = ["source": self.currentPlaybackSource]
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
