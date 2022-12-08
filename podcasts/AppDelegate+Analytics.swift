import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        guard FeatureFlag.tracks.enabled, !Settings.analyticsOptOut() else {
            return
        }

        addAnalyticsObservers()

        // Check if we're able to write to protected data
        if UIApplication.shared.isProtectedDataAvailable {
            setupAdapters()
        }
    }

    private func setupAdapters() {
        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter(), CrashLoggingAdapter()])
    }

    private func addAnalyticsObservers() {
        // Signed out events
        NotificationCenter.default.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let userIniated = userInfo["user_initiated"] as? Bool else {
                return
            }

            Analytics.track(.userSignedOut, properties: ["user_initiated": userIniated])
        }

        // Setup adapters if needed after protected data becomes available
        NotificationCenter.default.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
            self?.setupAdapters()
        }
    }

    /// Checks if we're missing the userId saved in the defaults, and retrieves it from the server if needed
    /// This should only need to be ran once.
    func retrieveUserIdIfNeeded() {
        guard
            let username = ServerSettings.syncingEmail(),
            let password = ServerSettings.syncingPassword(),
            ServerSettings.userId == nil
        else {
            return
        }

        FileLog.shared.addMessage("Missing User ID - Retrieving from the server")

        // Refresh the login, but only retrieve the userId
        ApiServerHandler.shared.validateLogin(username: username, password: password) { success, userId, _ in
            guard success, let userId else {
                return
            }

            ServerSettings.userId = userId
            NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        }
    }
}
