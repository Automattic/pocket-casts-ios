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
        if FeatureFlag.watchTransferUserInfoApi.enabled {
            handleStateUpdate(applicationContext)
        } else {
            if let messageId = applicationContext[WatchConstants.Keys.messageVersion] as? String, messageId == WatchConstants.Values.messageVersion {
                UserDefaults.standard.set(applicationContext, forKey: WatchConstants.UserDefaults.data)
                UserDefaults.standard.set(Date(), forKey: WatchConstants.UserDefaults.lastDataTime)
                updateFeatureFlags(applicationContext)
                NotificationCenter.default.post(name: WatchConstants.Notifications.dataUpdated, object: nil)
            }
        }
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
            } catch {
                assertionFailure("Failed to override \(flag.rawValue) with \(value): \(error)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let messageType = message[WatchConstants.Messages.messageType] as? String else { return }

        if WatchConstants.Messages.LogFileRequest.type == messageType {
            if FeatureFlag.watchLogFileTransfer.enabled {
                // Use file transfer for log delivery when flag is enabled
                sendLogFileViaTransfer()
                replyHandler([:])
            } else {
                FileLog.shared.loadLogFileAsString { logContents in
                    let response = [WatchConstants.Messages.LogFileRequest.logContents: logContents]
                    replyHandler(response)
                }
            }
        }
    }

    private func sendLogFileViaTransfer() {
        FileLog.shared.loadLogFileAsString { [weak self] logContents in
            guard self != nil else { return }

            // Write log contents to a temporary file for transfer
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("watch-log-transfer.txt")
            do {
                try logContents.write(to: tempURL, atomically: true, encoding: .utf8)
                let metadata: [String: Any] = [
                    WatchConstants.Messages.messageType: WatchConstants.Messages.LogFileTransfer.type
                ]
                WCSession.default.transferFile(tempURL, metadata: metadata)
            } catch {
                FileLog.shared.addMessage("SessionManager: Failed to write log file for transfer: \(error.localizedDescription)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard FeatureFlag.watchTransferUserInfoApi.enabled else { return }
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
        applyPhoneNowPlayingProgress()
        NotificationCenter.default.post(name: WatchConstants.Notifications.dataUpdated, object: nil)
    }

    /// When the phone pauses an episode the watch also has loaded locally (Watch source), apply the
    /// phone's position to the local player so the watch's Now Playing reflects it without a relaunch.
    /// This is the reverse of the watch→phone fast-path. We only mirror the settled (paused) position
    /// and never override an episode the watch is actively playing. `handleStateUpdate` has already
    /// rejected stale updates, and we add a last-write-wins guard on `playedUpToModified`.
    private func applyPhoneNowPlayingProgress() {
        guard FeatureFlag.watchPlaybackProgressLocalSync.enabled,
              !WatchDataManager.isPlaying(),
              let phoneEpisode = WatchDataManager.playingEpisode(),
              let localCurrent = PlaybackManager.shared.currentEpisode else { return }

        guard localCurrent.uuid == phoneEpisode.uuid else {
            FileLog.shared.addMessage("SessionManager: skipping phone progress - episode mismatch (local \(localCurrent.uuid), phone \(phoneEpisode.uuid))")
            return
        }
        guard !PlaybackManager.shared.isActivelyPlaying(episodeUuid: localCurrent.uuid) else {
            FileLog.shared.addMessage("SessionManager: skipping phone progress - watch is actively playing \(localCurrent.uuid)")
            return
        }

        let phonePlayedUpTo = WatchDataManager.currentTime()
        guard WatchDataManager.nowPlayingPlayedUpToModified() > localCurrent.playedUpToModified,
              Int64(localCurrent.playedUpTo) != Int64(phonePlayedUpTo) else { return }

        FileLog.shared.addMessage("SessionManager: applying phone playback progress \(phonePlayedUpTo) for \(localCurrent.uuid)")
        DispatchQueue.main.async {
            PlaybackManager.shared.seekToFromSync(time: phonePlayedUpTo, syncChanges: false, startPlaybackAfterSeek: false)
        }
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
