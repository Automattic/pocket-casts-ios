import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    private var haveAttemptedStateRestore = false

    func applicationDidFinishLaunching() {
        SessionManager.shared.setup()
        WatchSyncManager.shared.setup()
    }

    func applicationDidBecomeActive() {
        WatchSyncManager.shared.loginAndRefreshIfRequired()
        if WatchSyncManager.shared.isPlusUser() {
            scheduleNextRefresh()
        }

        restorePreviousStateIfRequired()
    }

    func applicationWillResignActive() {
        DownloadManager.shared.transferForegroundDownloadsToBackground()
    }

    func handleUserActivity(_ userInfo: [AnyHashable: Any]?) {
        restorePreviousStateIfRequired()
    }

    // indicates that the app was auto launched by watchOS because audio from the phone started playing. Isn't called when watchOS playback starts
    func handleRemoteNowPlayingActivity() {
        haveAttemptedStateRestore = true
        NavigationManager.shared.navigateToNowPlaying(source: .phone, fromLaunchEvent: true)
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                if WatchSyncManager.shared.isPlusUser() {
                    beginRefreshTask()
                    scheduleNextRefresh()
                }
                refreshTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(true)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                let identifier = urlSessionTask.sessionIdentifier
                if identifier == DownloadManager.cellBackgroundSessionId {
                    DownloadManager.shared.processBackgroundTaskCallback(task: urlSessionTask)
                } else if identifier.startsWith(string: BackgroundSyncManager.sessionIdPrefix) {
                    BackgroundSyncManager.shared.processBackgroundTaskCallback(task: urlSessionTask, identifier: identifier)
                } else {
                    urlSessionTask.setTaskCompletedWithSnapshot(true)
                }
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    // MARK: - State restoration

    private func restorePreviousStateIfRequired() {
        guard let lastPage = UserDefaults.standard.string(forKey: WatchConstants.UserDefaults.lastPage) else { return }

        let context = UserDefaults.standard.object(forKey: WatchConstants.UserDefaults.lastContext)
        if !haveAttemptedStateRestore {
            haveAttemptedStateRestore = true
            NavigationManager.shared.navigateToRestorable(name: lastPage, context: context)
        } else {
            // if we have a page we're meant to restore to, but are somehow still on the SourceInterfaceController, restore to that state again
            let visibleController = WKApplication.shared().visibleInterfaceController ?? WKApplication.shared().rootInterfaceController
            if visibleController is SourceInterfaceController {
                NavigationManager.shared.navigateToRestorable(name: lastPage, context: context)
            }
        }
    }

    // MARK: - Background Refresh

    private func beginRefreshTask() {
        if SyncManager.isFirstSyncInProgress() { return }

        FileLog.shared.addMessage("Starting a background refresh")
        let subscribedPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)
        BackgroundSyncManager.shared.performBackgroundRefresh(subscribedPodcasts: subscribedPodcasts)
    }

    private func scheduleNextRefresh() {
        // don't schedule incremental sync requests until first sync has been completed
        if SyncManager.isFirstSyncInProgress() { return }

        FileLog.shared.addMessage("Scheduling next refresh for 60 minutes time")
        let preferredDate = Date(timeIntervalSinceNow: 60.minutes)
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: preferredDate, userInfo: nil) { error in
            if let error = error {
                FileLog.shared.addMessage("Task scheduling error \(error.localizedDescription)")
            }
        }
    }
}
