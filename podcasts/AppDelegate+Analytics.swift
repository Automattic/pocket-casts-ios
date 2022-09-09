import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        guard FeatureFlag.tracksEnabled, !Settings.analyticsOptOut() else {
            return
        }

        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])

        addAnalyicsObservers()
    }

    private func addAnalyicsObservers() {
        // Signed out events
        NotificationCenter.default.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let userIniated = userInfo["user_initiated"] as? Bool else {
                return
            }

            Analytics.track(.userSignedOut, properties: ["user_initiated": userIniated])
        }
    }
}
