import PocketCastsServer

@Observable
class UserStateModel {

    var isPlusUser: Bool
    var isLoggedIn: Bool
    var usernameEmail: String?

    var usernameLabel: String {
        var usernameLabel = ""
        if isLoggedIn, isPlusUser {
            usernameLabel = usernameEmail ?? ""
        } else {
            if isLoggedIn {
                usernameLabel = usernameEmail ?? ""
            } else {
                usernameLabel = L10n.signedOut
            }
        }
        return usernameLabel
    }

    init() {
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        usernameEmail = ServerSettings.syncingEmail()
    }

    func refresh() {
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        usernameEmail = ServerSettings.syncingEmail()
    }
}
