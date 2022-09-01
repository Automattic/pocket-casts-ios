import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        guard FeatureFlag.tracksEnabled else {
            return
        }

        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])
    }
}
