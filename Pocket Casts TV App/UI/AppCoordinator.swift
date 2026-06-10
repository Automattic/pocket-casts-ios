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

    /// Logs the user out and removes all local data and cache, returning to the signed-out
    /// experience. Unlike iOS, tvOS keeps nothing locally once signed out.
    func logout() {
        Task {
            // Clear credentials first so anything below can't push the about-to-be-wiped data
            // up to the server.
            SignOutHelper.signout()

            // Stop audio and clear the queue before its backing data is removed (main actor).
            await MainActor.run {
                PlaybackManager.shared.endPlayback(saveCurrentEpisode: false)
            }

            DataManager.sharedManager.deleteAllData()
            DownloadManager.shared.removeAllDownloadedFiles()
            ImageManager.sharedManager.clearAllImageCaches()
            clearUserDefaults()

            await MainActor.run {
                userState.refresh()
                state = .welcome
            }
        }
    }

    /// Wipes `UserDefaults` apart from device-level keys, so the next account to sign in on a
    /// shared Apple TV doesn't inherit the previous user's preferences (playback speed, theme, …).
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard

        let preservedKeys = [
            Constants.UserDefaults.appId,
            Constants.UserDefaults.analyticsOptOut,
            Constants.UserDefaults.reviewRequestDates
        ]
        let preserved = preservedKeys.reduce(into: [String: Any]()) { result, key in
            result[key] = defaults.object(forKey: key)
        }

        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
        }

        for (key, value) in preserved {
            defaults.set(value, forKey: key)
        }
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
