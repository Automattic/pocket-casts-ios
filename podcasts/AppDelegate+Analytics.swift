import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    private var shouldRegisterAdapters: Bool {
        UIApplication.shared.isProtectedDataAvailable && !Settings.analyticsOptOut() && !Analytics.shared.adaptersRegistered
    }

    func setupAnalytics() {
        // Only setup if protected data is available, the user hasn't opted out, and we aren't already registered
        guard shouldRegisterAdapters else {
            return
        }

        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter(), CrashLoggingAdapter()])
    }

    func addAnalyticsObservers() {
        // Signed out events
        NotificationCenter.default.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let userIniated = userInfo["user_initiated"] as? Bool else {
                return
            }

            Analytics.track(.userSignedOut, properties: ["user_initiated": userIniated])
        }

        NotificationCenter.default.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
            self?.setupAnalytics()
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
