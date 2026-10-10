import Foundation
import PocketCastsServer
import PocketCastsUtils

class PCMessageSupportViewModel: MessageSupportViewModel {
    private static var requesterEmail: String {
        let syncEmail = ServerSettings.syncingEmail()
        let storedEmail = UserDefaults.standard.string(forKey: Constants.UserDefaults.supportEmail)

        let requesterEmail: String? = if SyncManager.isUserLoggedIn() {
            syncEmail ?? storedEmail
        } else {
            storedEmail ?? syncEmail
        }
        return requesterEmail ?? ""
    }

    // MARK: Init
    init(config: SupportConfig) {
        super.init(config: config,
                   requesterName: UserDefaults.standard.string(forKey: Constants.UserDefaults.supportName) ?? "",
                   requesterEmail: Self.requesterEmail,
                   isUserSignedIn: SyncManager.isUserLoggedIn())
    }

    override func submitRequest(ignoreUnavailableWatchLogs: Bool = false) {
        UserDefaults.standard.set(requesterName, forKey: Constants.UserDefaults.supportName)
        UserDefaults.standard.set(requesterEmail, forKey: Constants.UserDefaults.supportEmail)
        let emailMatchesAccount = ServerSettings.syncingEmail()?.caseInsensitiveCompare(requesterEmail) == .orderedSame
        FileLog.shared.addMessage("PCMessageSupportViewModel: submitRequest — signed in: \(isUserSignedIn), email matches account: \(emailMatchesAccount), name empty: \(requesterName.isEmpty), comment length: \(comment.count)")
        super.submitRequest(ignoreUnavailableWatchLogs: ignoreUnavailableWatchLogs)
    }
}
