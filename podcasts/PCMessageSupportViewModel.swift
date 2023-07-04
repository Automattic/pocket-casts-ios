import Foundation
import PocketCastsServer

class PCMessageSupportViewModel: MessageSupportViewModel {
    // MARK: Init

    init(config: SupportConfig) {
        super.init(config: config,
                   requesterName: UserDefaults.standard.string(forKey: Constants.UserDefaults.supportName) ?? "",
                   requesterEmail: UserDefaults.standard.string(forKey: Constants.UserDefaults.supportEmail) ?? ServerSettings.syncingEmail() ?? "")
    }

    override func submitRequest(ignoreUnavailableWatchLogs: Bool = false) {
        UserDefaults.standard.set(requesterName, forKey: Constants.UserDefaults.supportName)
        UserDefaults.standard.set(requesterEmail, forKey: Constants.UserDefaults.supportEmail)
        super.submitRequest(ignoreUnavailableWatchLogs: ignoreUnavailableWatchLogs)
    }
}
