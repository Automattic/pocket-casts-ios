import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils
import Firebase
import FirebaseRemoteConfig

@Observable
class AppCoordinator {
    enum State: Equatable {
        case loading
        case welcome
        case browsing
        case signedIn
        case userSync
        case dataLossResync
        case serverSignedOut
    }

    var state: State = .loading

    var userState = UserStateModel()

    func load() async {
        // Ensure database and tables are setup before we go forward
        let _ = DataManager.sharedManager

        checkDefaults()

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

        setupSignOutObservation()
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

        FirebaseManager.refreshRemoteConfig { [weak self] _ in
            self?.updateRemoteFeatureFlags()
        }
    }

    /// Applies remotely overridden feature flags to the `FeatureFlagOverrideStore`, so the rest of
    /// the app reads them through `FeatureFlag.enabled`. Mirrors `AppDelegate`/`AppClipAppDelegate`,
    /// each of which owns its own copy; skipped in debug builds where local overrides take precedence.
    private func updateRemoteFeatureFlags(forceReload: Bool = false) {
        guard BuildEnvironment.current != .debug || forceReload else { return }

        FeatureFlag.allCases.forEach { flag in
            guard let remoteKey = flag.remoteKey else { return }
            let remoteValue = RemoteConfig.remoteConfig().configValue(forKey: remoteKey)
            guard remoteValue.source == .remote else { return }
            do {
                FileLog.shared.console("Override \(flag): \(remoteValue.boolValue)")
                try FeatureFlagOverrideStore().override(flag, withValue: remoteValue.boolValue)
            } catch {
                FileLog.shared.addMessage("Failed to set remote feature flag \(flag): \(error)")
            }
        }
    }

    private func setupDiscover() {
        Task {
            let _ = await DiscoverServerHandler.shared.discoverPage()
        }
    }

    private func setupSignOutObservation() {
        NotificationCenter.default.addObserver(forName: .serverUserWillBeSignedOut, object: nil, queue: .main) { [weak self] notification in
            self?.handleSignOutNotification(notification)
        }
    }

    private func handleSignOutNotification(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let userInitiated = userInfo["user_initiated"] as? Bool,
            userInitiated == false
        else {
            return
        }
        state = .serverSignedOut
    }

    private func checkDefaults() {
        performUpdateIfRequired(updateKey: "v1_run") {
            FileLog.shared.addMessage("AppCoordinator v1Run")
            // ensure that all previous log in information is wiped and database cleanup
            SyncManager.clearTokensFromKeyChain()
            DataManager.sharedManager.deleteAllData()
        }
    }

    private func performUpdateIfRequired(updateKey: String, update: () -> Void) {
        if UserDefaults.standard.bool(forKey: updateKey) { return } // already performed this update

        update()
        UserDefaults.standard.set(true, forKey: updateKey)
        UserDefaults.standard.synchronize()
    }

    func remotePlayPauseToggle() {
        AnalyticsPlaybackHelper.shared.timestampOfLastRemoteAction = .now
        PlaybackManager.shared.remotePlayPauseToggle()
    }
}
