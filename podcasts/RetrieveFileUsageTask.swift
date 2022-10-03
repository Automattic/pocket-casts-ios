import DataModel
import Foundation
import SwiftProtobuf
import Utils

class RetrieveFileUsageTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files/usage/"

        do {
            var headers: [String: String]?
            if let lastModified = Settings.filesUsageLastModified() {
                headers = [Server.HttpHeaders.ifModifiedSince: lastModified]
            }
            let (data, httpResponse) = getToServer(url: url, token: token, customHeaders: headers)

            if httpResponse?.statusCode == Server.HttpConstants.notModified {
                FileLog.shared.addMessage("RetrieveFileUsageTask - not modified, no changes required")
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.userEpisodesRefreshed)
                return
            }

            guard let responseData = data, httpResponse?.statusCode == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("RetrieveFileUsageTask  - server returned \(httpResponse?.statusCode ?? -1), firing refresh failed")
                return
            }

            do {
                let serverResponse = try Files_AccountUsage(serializedData: responseData)

                Settings.setCustomStorageUserLimit(Int(serverResponse.totalSize))
                Settings.setCustomStorageUsed(Int(serverResponse.usedSize))
                Settings.setCustomStorageNumFiles(Int(serverResponse.totalFiles))
                FileLog.shared.addMessage("Total user files  \(serverResponse.totalFiles), total size \(serverResponse.totalSize) used size \(serverResponse.usedSize)")

                if let lastModified = httpResponse?.allHeaderFields[Server.HttpHeaders.lastModified] as? String {
                    Settings.setFilesUsageLastModified(lastModified)
                }
            } catch {
                FileLog.shared.addMessage("Decoding User episodes failed \(error.localizedDescription)")
            }
        }
    }
}
