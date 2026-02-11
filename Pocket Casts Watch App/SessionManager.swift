import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import WatchConnectivity
import WatchKit

class SessionManager: NSObject, WCSessionDelegate {
    static let shared = SessionManager()

    override init() {
        super.init()

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func setup() {
        // wake up the app if we don't have any data, this should cause it to send us some
        if WatchDataManager.playlists() == nil {
            requestData()
        }
    }

    func handleBackgroundTask(task: WKWatchConnectivityRefreshBackgroundTask) {}

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        setup()
    }

    // this is called in the background when there's new data available for the app
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleStateUpdate(applicationContext)
    }

    func updateFeatureFlags(_ applicationContext: [String: Any]) {
        guard let flags = applicationContext[WatchConstants.Keys.featureFlags] as? [String: Bool] else {
            assertionFailure("Failed to receive FeatureFlags to Watch")
            return
        }

        FeatureFlag.allCases.forEach { flag in
            let value = flags[flag.rawValue] ?? flag.default
            do {
                try FeatureFlagOverrideStore().override(flag, withValue: value)
            } catch let error {
                assertionFailure("Failed to override \(flag.rawValue) with \(value): \(error)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let messageType = message[WatchConstants.Messages.messageType] as? String else { return }

        if WatchConstants.Messages.LogFileRequest.type == messageType {
            FileLog.shared.loadLogFileAsString { logContents in
                let response = [WatchConstants.Messages.LogFileRequest.logContents: logContents]
                replyHandler(response)
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let messageType = message[WatchConstants.Messages.messageType] as? String else { return }

        if WatchConstants.Messages.StateUpdate.type == messageType {
            handleStateUpdate(message)
        }
    }

    // MARK: - State Update Handler

    private static let lastProcessedTimestampKey = "lastProcessedStateUpdateTimestamp"

    private func handleStateUpdate(_ stateData: [String: Any]) {
        guard let messageId = stateData[WatchConstants.Keys.messageVersion] as? String,
              messageId == WatchConstants.Values.messageVersion else {
            return
        }

        // Validate timestamp to ignore stale updates
        // This prevents old queued applicationContext data from overwriting newer sendMessage data
        if let newTimestamp = stateData[WatchConstants.Keys.lastUpdateTime] as? TimeInterval {
            let lastProcessed = UserDefaults.standard.double(forKey: Self.lastProcessedTimestampKey)
            if newTimestamp <= lastProcessed {
                FileLog.shared.addMessage("SessionManager: Ignoring stale state update (timestamp: \(newTimestamp), last processed: \(lastProcessed))")
                return
            }
            UserDefaults.standard.set(newTimestamp, forKey: Self.lastProcessedTimestampKey)
        }

        UserDefaults.standard.set(stateData, forKey: WatchConstants.UserDefaults.data)
        UserDefaults.standard.set(Date(), forKey: WatchConstants.UserDefaults.lastDataTime)
        updateFeatureFlags(stateData)
        NotificationCenter.default.post(name: WatchConstants.Notifications.dataUpdated, object: nil)
    }

    // MARK: - Offline watch messages

    func requestData() {
        guard WCSession.default.isReachable else { return }

        let wakeUpMessage = [WatchConstants.Messages.messageType: WatchConstants.Messages.DataRequest.type]
        WCSession.default.sendMessage(wakeUpMessage, replyHandler: nil, errorHandler: nil)
    }

    func requestLoginDetails(replyHandler: (([String: Any]) -> Swift.Void)?, errorHandler: ((Error?) -> Swift.Void)? = nil) {
        if !WCSession.default.isReachable {
            errorHandler?(nil)

            return
        }

        let loginRequest = [WatchConstants.Messages.messageType: WatchConstants.Messages.LoginDetailsRequest.type]
        WCSession.default.sendMessage(loginRequest, replyHandler: { response in
            replyHandler?(response)
        }) { error in
            errorHandler?(error)
        }
    }
}
