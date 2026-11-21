#if DEBUG
import Foundation
import Intents
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

/// Switches a debug build between the production and staging servers.
///
/// Local data belongs to the server it came from, so a switch signs out and deletes the database, downloads, Siri
/// donations and settings, keeping only the feature flag overrides and the analytics opt-out. The developer menu saves
/// the choice and closes the app, and the next launch applies it before anything reads that data. A launch with
/// `PC_SERVER=staging` or `PC_SERVER=production` in its environment applies it right away. The choice stays until the
/// next switch, including across Debug and Staging builds, which share a bundle ID.
enum ServerEnvironmentSwitch {
    private static let selectedKey = "ServerEnvironment"
    private static let requestedKey = "ServerEnvironmentRequested"
    private static let launchVariable = "PC_SERVER"

    /// Runs first at launch, before anything reads local data or makes a request.
    static func prepareForLaunch() {
        let defaults = UserDefaults.standard
        let selected = defaults.string(forKey: selectedKey).flatMap(ServerEnvironment.init) ?? .buildDefault
        let requested = (ProcessInfo.processInfo.environment[launchVariable] ?? defaults.string(forKey: requestedKey))
            .flatMap(ServerEnvironment.init)
        defaults.removeObject(forKey: requestedKey)

        if let requested, requested != selected {
            deleteLocalData()
            defaults.set(requested.rawValue, forKey: selectedKey)
            FileLog.shared.addMessage("ServerEnvironmentSwitch: switched from \(selected.rawValue) to \(requested.rawValue)")
        }
        ServerEnvironment.current = requested ?? selected
    }

    /// Saves the choice and closes the app. The next launch applies it.
    static func switchOnNextLaunch(to environment: ServerEnvironment) {
        UserDefaults.standard.set(environment.rawValue, forKey: requestedKey)
        UserDefaults.standard.synchronize()
        exit(0)
    }

    private static func deleteLocalData() {
        SyncManager.clearTokensFromKeyChain()

        let fileManager = FileManager.default
        let documents = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let databaseFiles = (DataManager.databaseFilePaths() + [DataManager.pathToDbBackup()]).map(URL.init(fileURLWithPath:))
        let downloadFolders = [
            documents.appendingPathComponent("podcasts_non_backed_up"),
            documents.appendingPathComponent("podcasts_buffered"),
            documents.appendingPathComponent("custom_images"),
            caches.appendingPathComponent("temp_download")
        ]
        for url in databaseFiles + downloadFolders {
            try? fileManager.removeItem(at: url)
        }

        if let domain = Bundle.main.bundleIdentifier {
            let defaults = UserDefaults.standard
            let featureFlags = FeatureFlagOverrideStore()
            let kept = (defaults.persistentDomain(forName: domain) ?? [:]).filter { key, _ in
                featureFlags.isOverrideKey(key) || key == Constants.UserDefaults.analyticsOptOut
            }
            defaults.setPersistentDomain(kept, forName: domain)
        }
        let groupId = SharedConstants.GroupUserDefaults.groupContainerId
        UserDefaults(suiteName: groupId)?.removePersistentDomain(forName: groupId)

        INInteraction.deleteAll()
    }
}
#endif
