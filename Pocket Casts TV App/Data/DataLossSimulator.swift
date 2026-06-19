import Foundation
import PocketCastsDataModel
import PocketCastsUtils

/// Reproduces the tvOS "system purged our files" scenario for testing. Launch with the
/// `-PCSimulateDataLoss` argument (Xcode ▸ Edit Scheme ▸ Run ▸ Arguments) to delete the
/// database files while leaving the keychain login and sync watermarks intact, just as
/// tvOS reclaiming the Caches directory would. Run once normally first, then relaunch
/// with the argument set to trigger the resync.
enum DataLossSimulator {
    static let launchArgument = "-PCSimulateDataLoss"

    static func simulateIfRequested() {
        // Non-App Store builds only, to keep it out of release paths.
        guard BuildEnvironment.current == .debug else { return }
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }

        FileLog.shared.addMessage("⚠️ DataLossSimulator: \(launchArgument) is set — wiping the database to simulate a tvOS file purge")

        // Remove the database file set so a clean one is recreated on first access.
        for path in DataManager.databaseFilePaths() where FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
                FileLog.shared.addMessage("DataLossSimulator: removed \(path)")
            } catch {
                FileLog.shared.addMessage("DataLossSimulator: failed to remove \(path): \(error)")
            }
        }
    }
}
