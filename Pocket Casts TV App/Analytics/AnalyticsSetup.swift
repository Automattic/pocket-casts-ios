import Foundation
import PocketCastsServer

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

        addObservers()
    }

    /// Mirrors the iOS `AppDelegate+Analytics` observer so that signing out —
    /// whether user-initiated from the profile menu or forced by the server —
    /// fires `userSignedOut`. The notification is posted by `SyncManager.signout`.
    private static func addObservers() {
        NotificationCenter.default.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let userInitiated = userInfo["user_initiated"] as? Bool else {
                return
            }

            Analytics.track(.userSignedOut, properties: ["user_initiated": userInitiated])
        }
    }
}
