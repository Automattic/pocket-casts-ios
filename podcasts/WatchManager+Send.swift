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
            Task {
                let log = await logCache.getCachedLog()
                completion(log)
            }
            return
        }

        // Hold a local reference so we don't potentially run into a deallocated `self` when the below blocks are run.
        Task { [weak self] in
            guard let self else { return }
            let cachedLog = await self.logCache.getCachedLog()

            // Use an actor to ensure thread-safe completion handling
            let completionHandler = CompletionHandler(cachedLog: cachedLog, completion: completion)

            // since we don't know how long it takes for a send message to timeout, wait only 5 seconds for a watch response before giving up here
            let task = Task { [weak self, completionHandler] in
                try? await Task.sleep(for: .seconds(5))
                let cachedLogForTimeout = await self?.logCache.getCachedLog()
                await completionHandler.callCompletionIfNeeded(with: cachedLogForTimeout)
                await self?.logTaskManager.clearTask()
            }

            await logTaskManager.setTask(task)

            // if we get here then it's likely we'll be able to ask the watch for a log file, so let's try
            let logRequestMessage = [WatchConstants.Messages.messageType: WatchConstants.Messages.LogFileRequest.type]
            session.sendMessage(logRequestMessage, replyHandler: { [weak self] response in
                Task { [weak self, completionHandler] in
                    await self?.logTaskManager.cancelCurrentTask()

                    if let logContents = response[WatchConstants.Messages.LogFileRequest.logContents] as? String {
                        await self?.logCache.setCachedLog(logContents)
                        if FeatureFlag.refreshAndSaveWatchLogsOnSend.enabled {
                            self?.saveLog(contents: logContents)
                        }
                        await completionHandler.callCompletionIfNeeded(with: logContents)
                    } else {
                        let cachedLog = await self?.logCache.getCachedLog()
                        await completionHandler.callCompletionIfNeeded(with: cachedLog)
                    }
                }
            }) { [weak self] error in
                Task { [weak self, completionHandler] in
                    await self?.logTaskManager.cancelCurrentTask()

                    // To avoid spamming the logs, we'll only log errors unrelated to unreachable
                    let nsError = error as NSError
                    if nsError.domain == WCErrorDomain,
                       nsError.code != WCError.Code.notReachable.rawValue {
                        FileLog.shared.addMessage("WatchManager: Failed log collection \(error)")
                    }

                    let cachedLog = await self?.logCache.getCachedLog()
                    await completionHandler.callCompletionIfNeeded(with: cachedLog)
                }
            }
        }
    }

    /// Async wrapper for requestLogFile for cleaner call sites
    func requestLogFile() async -> String? {
        await withCheckedContinuation { continuation in
            requestLogFile { result in
                continuation.resume(returning: result)
            }
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

// MARK: - Helper Actor for Thread-Safe Completion Handling
actor CompletionHandler {
    private var hasCalledCompletion = false
    private let cachedLog: String?
    private let completion: (String?) -> Void

    init(cachedLog: String?, completion: @escaping (String?) -> Void) {
        self.cachedLog = cachedLog
        self.completion = completion
    }

    func callCompletionIfNeeded(with result: String?) {
        guard !hasCalledCompletion else { return }
        hasCalledCompletion = true
        completion(result)
    }
}
