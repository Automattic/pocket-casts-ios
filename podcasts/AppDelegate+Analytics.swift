extension AppDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [TracksLoggingAdapter(), TracksAdapter()])

        #warning("TODO: Remove this")
        Analytics.track(.applicationOpened)
    }
}
