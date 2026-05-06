import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

@Observable
class AppCoordinator {
    enum State {
        case loading
        case welcome
        case browsing
        case signedIn
        case userSync
    }

    var state: State = .loading

    func load() async {
        // Ensure database and tables are setup before we go forward
        let _ = DataManager.sharedManager

        ServerConfig.shared.syncDelegate = ServerSyncManager.shared

        setupCredentials()

        setupUniqueAppId()

        state = .welcome
    }

    private func setupCredentials() {
        ServerCredentials.sharing = ApiCredentials.sharingServerSecret
    }

    private func setupUniqueAppId() {
        let defaults = UserDefaults.standard

        // check to see that this app has a unique ID, if not create one
        let uniqueId = defaults.string(forKey: Constants.UserDefaults.appId)
        if uniqueId?.count ?? 0 < 1 {
            let uuid = UUID().uuidString
            defaults.set(uuid, forKey: Constants.UserDefaults.appId)
            defaults.synchronize()
        }
    }
}
