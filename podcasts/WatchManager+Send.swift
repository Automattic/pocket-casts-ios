import Foundation
import WatchConnectivity

extension WatchManager {
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

        // since we don't know how long it takes for a send message to timeout, wait only 10 seconds for a watch response before giving up here
        var haveCalledCompletion = false
        logFileRequestTimedAction.startTimer(for: 5.seconds) { [weak self] in
            if haveCalledCompletion { return }

            haveCalledCompletion = true

            completion(self?.cachedLog)
        }

        // if we get here then it's likely we'll be able to ask the watch for a log file, so let's try
        let logRequestMessage = [WatchConstants.Messages.messageType: WatchConstants.Messages.LogFileRequest.type]
        session.sendMessage(logRequestMessage, replyHandler: { [weak self] response in
            if haveCalledCompletion { return }
            haveCalledCompletion = true

            self?.logFileRequestTimedAction.cancelTimer()
            if let logContents = response[WatchConstants.Messages.LogFileRequest.logContents] as? String {
                self?.cachedLog = logContents
                completion(logContents)
            } else {
                completion(self?.cachedLog)
            }

        }) { [weak self] _ in
            if haveCalledCompletion { return }
            haveCalledCompletion = true

            completion(self?.cachedLog)
        }
    }
}
