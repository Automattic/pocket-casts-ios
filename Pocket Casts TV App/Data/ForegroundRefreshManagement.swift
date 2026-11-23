import Foundation
import PocketCastsServer
import PocketCastsUtils
import SwiftUI

/// Refreshes podcasts when the app returns to the foreground, mirroring the iOS app's
/// `handleBecomeActive`. Launch is handled by `AppCoordinator`, so only a return from
/// `.background` triggers a refresh.
class ForegroundRefreshManagement {

    private static let minTimeBetweenRefreshes = 1.minutes

    private let refreshManager: RefreshManager
    private var wasInBackground = false

    init(refreshManager: RefreshManager = .shared) {
        self.refreshManager = refreshManager
    }

    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .background:
            wasInBackground = true
        case .active:
            guard wasInBackground else { return }
            wasInBackground = false
            didEnterForeground()
        default:
            break
        }
    }

    private func didEnterForeground() {
        guard SyncManager.isUserLoggedIn(),
              DateUtil.hasEnoughTimePassed(since: ServerSettings.lastRefreshEndTime(), time: Self.minTimeBetweenRefreshes) else {
            return
        }

        refreshManager.refreshPodcasts()
    }
}
