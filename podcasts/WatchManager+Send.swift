import Foundation
import WatchConnectivity
import PocketCastsUtils

extension WatchManager {
    private static let watchLogFileName = "watch-logs.txt"

    /// Requests the Apple Watch log contents.
    /// If anything is returned, it is also saved in a cache so in case any
    /// subsequent call fails, it will return from the cache.
    func requestLogFile(completion: @escaping (String?) -> Void) {
        // check that the user actually has a watch and it's connected
        guard WCSession.isSupported() else {
            completion(nil)

            return
        }

        let session = WCSession.default
        if session.activationState != .activated || session.isPaired == false || session.isWatchAppInstalled == false {
            completion(cachedLog)

            return
        }

        // Hold a local reference so we don't potentially run into a deallocated `self` when the below blocks are run.
        let cachedLog = self.cachedLog

        // since we don't know how long it takes for a send message to timeout, wait only 5 seconds for a watch response before giving up here
        var haveCalledCompletion = false
        logFileRequestTask = Task { [cachedLog] in
            try? await Task.sleep(for: .seconds(5))
            if haveCalledCompletion { return }

            haveCalledCompletion = true
            completion(cachedLog)
        }

        // if we get here then it's likely we'll be able to ask the watch for a log file, so let's try
        let logRequestMessage = [WatchConstants.Messages.messageType: WatchConstants.Messages.LogFileRequest.type]
        session.sendMessage(logRequestMessage, replyHandler: { [weak self] response in
            if haveCalledCompletion { return }
            haveCalledCompletion = true

            self?.logFileRequestTask?.cancel()
            if let logContents = response[WatchConstants.Messages.LogFileRequest.logContents] as? String {
                self?.cachedLog = logContents
                if FeatureFlag.refreshAndSaveWatchLogsOnSend.enabled {
                    self?.saveLog(contents: logContents)
                }
                completion(logContents)
            } else {
                completion(cachedLog)
            }

        }) { error in
            if haveCalledCompletion { return }
            haveCalledCompletion = true

            FileLog.shared.addMessage("WatchManager: Failed log collection \(error)")

            completion(cachedLog)
        }
    }

    func readLogFile() -> String? {
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(Self.watchLogFileName)
        let contents = try? String(contentsOf: filePath, encoding: .utf8)
        return contents
    }

    private func saveLog(contents: String) {
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(Self.watchLogFileName)
        let backupPath = FileManager.default.temporaryDirectory.appendingPathComponent("watch-logs-backup.txt")
        let rotator = FileRotator(fileManager: FileManager.default, targetFilePath: filePath.path, backupFilePath: backupPath.path, loggingTo: nil)
        rotator.rotateFile(ifSizeExceeds: 100.kilobytes)
        do {
            try contents.write(to: filePath, atomically: false, encoding: .utf8)
        } catch let error {
            FileLog.shared.addMessage("Failed to save cached watch log file: \(error.localizedDescription)")
        }
    }
}
