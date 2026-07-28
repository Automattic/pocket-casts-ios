import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct SuggestedFoldersResponse {
    public let suggestions: [String: [String]]
}

class SuggestedFoldersTask: ApiBaseTask, @unchecked Sendable {
    var uuids: [String]
    var language: String
    var completion: ((SuggestedFoldersResponse?) -> Void)?

    init(uuids: [String], language: String, completion: ((SuggestedFoldersResponse?) -> Void)?) {
        self.uuids = uuids
        self.language = language
        self.completion = completion
    }

    override func main() {
        doNetworkCall()
    }

    func doNetworkCall() {
        let urlString = "\(ServerConstants.Urls.cache())podcast/suggest_folders"

        do {
            guard let requestData = try? JSONSerialization.data(withJSONObject: ["language": language, "uuids": uuids]) else {
                FileLog.shared.addMessage("Failed to encode uuids for suggested folders call")
                completion?(nil)
                return
            }

            let (data, statusCode) = super.performPostToServer(url: urlString, token: nil, data: requestData)
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
