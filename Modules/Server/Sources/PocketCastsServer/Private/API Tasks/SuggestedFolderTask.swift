import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct SuggestedFoldersResponse {
    public let suggestions: [String: [String]]
}

class SuggestedFoldersTask: ApiBaseTask, @unchecked Sendable {
    var uuids: [String]
    var completion: ((SuggestedFoldersResponse?) -> Void)?

    init(uuids: [String], completion: ((SuggestedFoldersResponse?) -> Void)?) {
        self.uuids = uuids
        self.completion = completion
    }

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.cache())podcast/suggest_folders"

        do {
            guard let requestData = try? JSONSerialization.data(withJSONObject: ["language": "en", "uuids": uuids]) else {
                FileLog.shared.addMessage("Failed to encode uuids for suggested folders call")
                completion?(nil)
                return
            }

            let (data, statusCode) = super.performPostToServer(url: urlString, token: token, data: requestData)
            guard let responseData = data,
                  statusCode == ServerConstants.HttpConstants.ok
            else {
                FileLog.shared.addMessage("Failed to get suggested folders - server returned \(statusCode)")
                completion?(nil)
                return
            }
            let validationResponse = try JSONSerialization.jsonObject(with: responseData)
            guard let jsonDictionary = validationResponse as? [String: [String]] else {
                FileLog.shared.addMessage("Failed to parse Suggested Folders Response - not a dictionary")
                completion?(nil)
                return
            }
            let suggestions = SuggestedFoldersResponse(suggestions: jsonDictionary)
            completion?(suggestions)
        } catch {
            FileLog.shared.addMessage("Failed to parse Suggested Folders Response \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
