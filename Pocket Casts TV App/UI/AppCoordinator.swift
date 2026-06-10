import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import Firebase

@Observable
class AppCoordinator {
    enum State {
        case loading
        case welcome
        case browsing
        case signedIn
        case userSync
        case dataLossResync
    }

    var state: State = .loading

    var userState = UserStateModel()

    func load() async {
        // Ensure database and tables are setup before we go forward
        let _ = DataManager.sharedManager

        ServerConfig.shared.syncDelegate = ServerSyncManager.shared
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared

        setupCredentials()

        setupUniqueAppId()

        setupFirebase()

        // Fresh database + still logged in (keychain survived) = the system purged our
        // data; re-fetch everything behind a spinner first.
        let needsDataLossResync = DataManager.sharedManager.databaseWasCreated && SyncManager.isUserLoggedIn()

        await MainActor.run {
            userState.refresh()
            if userState.isLoggedIn {
                state = needsDataLossResync ? .dataLossResync : .signedIn
            } else {
                state = .welcome
            }
        }
        // The resync screen drives its own full sync.
        if userState.isLoggedIn, !needsDataLossResync {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
            RefreshManager.shared.syncUpNext()
        }

        setupDiscover()
    }

    func signIn() {
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

    private func setupFirebase() {
        FirebaseApp.configure()
    }

    private func setupDiscover() {
        Task {
            let _ = await DiscoverServerHandler.shared.discoverPage()
        }
    }
}
