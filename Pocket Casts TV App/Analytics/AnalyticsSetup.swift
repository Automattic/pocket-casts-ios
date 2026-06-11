import Foundation

enum AnalyticsSetup {
    private static var didSetup = false

    static func setupIfNeeded() {
        guard !didSetup else { return }
        didSetup = true

        var adapters: [AnalyticsAdapter] = []

        if !Settings.analyticsOptOut() {
            adapters = [AnalyticsLoggingAdapter(), TracksAdapter()]
#if DEBUG
            adapters.append(AnalyticsOSLogAdapter())
#endif
        }
        
        adapters.append(LiveAnalyticsStreamer())
        
        Analytics.register(adapters: adapters)
    }
}
