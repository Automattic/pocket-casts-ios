extension AppDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])

        #warning("TODO: Remove this")
        Analytics.track(.applicationOpened)
    }
}
