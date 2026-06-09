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
    }

    var state: State = .loading

    var userState = UserStateModel()

    /// An action parked while the viewer creates an account. The create-account
    /// flow resets the app (so the action can't live in a view that's about to be
    /// torn down); it's replayed by ``runPendingAccountAction()`` once sign-in
    /// completes. See `RequireAccount`.
    var pendingAccountAction: (() -> Void)?

    func load() async {
        // Ensure database and tables are setup before we go forward
        let _ = DataManager.sharedManager

        ServerConfig.shared.syncDelegate = ServerSyncManager.shared
        ServerConfig.shared.playbackDelegate = PlaybackManager.shared

        setupCredentials()

        setupUniqueAppId()

        setupFirebase()

        await MainActor.run {
            userState.refresh()
            if userState.isLoggedIn {
                state = .signedIn
            } else {
                state = .welcome
            }
        }
        if userState.isLoggedIn {
            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
            RefreshManager.shared.syncUpNext()
        }

        setupDiscover()
    }

    func signIn() {
        state = .welcome
    }

    /// Runs and clears any action parked in ``pendingAccountAction`` (set when a
    /// signed-out viewer triggered a sign-in-gated action and was sent to create
    /// an account). Called once sign-in completes; a no-op otherwise.
    func runPendingAccountAction() {
        let action = pendingAccountAction
        pendingAccountAction = nil
        // Only replay once sign-in actually succeeded — a failed sync also lands
        // here, and a login-gated action must not run while signed out.
        guard userState.isLoggedIn else { return }
        action?()
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
