import Foundation
import PocketCastsUtils
import UIKit

// MARK: - Opt out/in

extension Analytics {
    func optOutOfAnalytics() {
        Analytics.track(.analyticsOptOut)
        Settings.setAnalytics(optOut: true)
        refreshRegistered()
    }

    func optInOfAnalytics() {
#if !os(watchOS) && !APPCLIP && !os(tvOS)
        Settings.setAnalytics(optOut: false)
        setAdaptersRegisteredStatus(false)
        (UIApplication.shared.delegate as? AppDelegate)?.setupAnalytics()
        Analytics.track(.analyticsOptIn)
#endif
    }

    func refreshRegistered() {
        if Settings.analyticsOptOut() {
            Analytics.unregister()
        }
#if !os(watchOS) && !APPCLIP && !os(tvOS)
        (UIApplication.shared.delegate as? AppDelegate)?.setupAnalytics()
#endif
        FileLog.shared.addMessage("Analytics: Refreshed Registered Adapters")
        Analytics.logCurrentAdapters()
    }
}
