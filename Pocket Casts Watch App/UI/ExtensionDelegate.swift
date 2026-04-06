import AutomatticRemoteLogging
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    private var haveAttemptedStateRestore = false
    private var crashLogging: CrashLogging?

    func applicationDidFinishLaunching() {
        setupCrashLogging()

        SessionManager.shared.setup()
        WatchSyncManager.shared.setup()
        restorePreviousStateIfRequired()
    }

    private func setupCrashLogging() {
        crashLogging = try? CrashLogging(dataProvider: WatchCrashLoggingDataProvider()).start()
        if let crashLogging = crashLogging {
            ServerConfig.shared.errorLogger = WatchCrashLoggingErrorLogger(crashLogging: crashLogging)
        }
    }

    func applicationDidBecomeActive() {
        WatchSyncManager.shared.loginAndRefreshIfRequired()
        if WatchSyncManager.shared.isPlusUser() {
            scheduleNextRefresh()
        }
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
        FileLog.shared.addMessage("Watch Extension Delegate start handle background task")
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                if WatchSyncManager.shared.isPlusUser() {
                    FileLog.shared.addMessage("Watch Extension Delegate start application refresh background task")
                    beginRefreshTask()
                    scheduleNextRefresh()
                }
                refreshTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTask.setTaskCompletedWithSnapshot(true)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                FileLog.shared.addMessage("Watch Extension Delegate start url session refresh background task")
                let identifier = urlSessionTask.sessionIdentifier
                if identifier == DownloadManager.cellBackgroundSessionId {
                    FileLog.shared.addMessage("Watch Extension Delegate start url session download refresh background task")
                    DownloadManager.shared.processBackgroundTaskCallback(task: urlSessionTask)
                } else if identifier.startsWith(string: BackgroundSyncManager.sessionIdPrefix) {
                    FileLog.shared.addMessage("Watch Extension Delegate start url session upnext refresh background task")
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

// MARK: - Crash Logging

private class WatchCrashLoggingDataProvider: AutomatticRemoteLogging.CrashLoggingDataProvider {
    let sentryDSN = ApiCredentials.sentryDSN
    let userHasOptedOut = false
    let shouldEnableAutomaticSessionTracking = true

    var currentUser: AutomatticTracksModel.TracksUser? {
        guard SyncManager.isUserLoggedIn() else {
            return nil
        }
        return TracksUser(userID: ServerSettings.userId, email: ServerSettings.syncingEmail(), username: nil)
    }

    var buildType: String {
        #if STAGING
        return "staging"
        #elseif DEBUG
        return "debug"
        #else
        return "appStore"
        #endif
    }
}

private struct WatchCrashLoggingErrorLogger: ErrorLogger {
    let crashLogging: CrashLogging

    func log(error: Error, context: [String: String]?) {
        if FeatureFlag.watchSentryLogs.enabled {
            crashLogging.logError(error, tags: context ?? [:], level: .warning)
        }
    }
}
