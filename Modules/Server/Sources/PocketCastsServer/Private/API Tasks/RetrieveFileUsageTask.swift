import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveFileUsageTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/usage/"

        do {
            var headers: [String: String]?
            if let lastModified = ServerSettings.filesUsageLastModified() {
                headers = [ServerConstants.HttpHeaders.ifModifiedSince: lastModified]
            }
            let (data, httpResponse) = getToServer(url: url, token: token, customHeaders: headers)

            if httpResponse?.statusCode == ServerConstants.HttpConstants.notModified {
                FileLog.shared.addMessage("RetrieveFileUsageTask - not modified, no changes required")
                NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshed, object: nil)
                return
            }

            guard let responseData = data, httpResponse?.statusCode == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("RetrieveFileUsageTask  - server returned \(httpResponse?.statusCode ?? -1), firing refresh failed")
                return
            }

            do {
                let serverResponse = try Files_AccountUsage(serializedData: responseData)

                ServerSettings.setCustomStorageUserLimit(Int(serverResponse.totalSize))
                ServerSettings.setCustomStorageUsed(Int(serverResponse.usedSize))
                ServerSettings.setCustomStorageNumFiles(Int(serverResponse.totalFiles))
                FileLog.shared.addMessage("Total user files  \(serverResponse.totalFiles), total size \(serverResponse.totalSize) used size \(serverResponse.usedSize)")

                if let lastModified = httpResponse?.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String {
                    ServerSettings.setFilesUsageLastModified(lastModified)
                }
            } catch {
                FileLog.shared.addMessage("Decoding User episodes failed \(error.localizedDescription)")
            }
        }
    }
}
