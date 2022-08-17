import PocketCastsServer
import PocketCastsUtils

extension AppDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])
    }
}

extension AppDelegate {
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
            guard success, let userId = userId else {
                return
            }

            ServerSettings.userId = userId
            NotificationCenter.default.post(name: .userLoginDidChange, object: nil)
        }
    }
}
