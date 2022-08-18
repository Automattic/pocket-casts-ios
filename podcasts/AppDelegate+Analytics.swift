import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])
    }
}
