import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveBookmarksTask: ApiBaseTask {
    typealias BookmarkRetrievedHandler = ([Api_BookmarkResponse]?) -> Void

    let onBookmarksRetrieved: BookmarkRetrievedHandler

    init(onBookmarksRetrieved: @escaping BookmarkRetrievedHandler, dataManager: DataManager = .sharedManager) {
        self.onBookmarksRetrieved = onBookmarksRetrieved
        super.init(dataManager: dataManager)
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/bookmark/list"

        guard let data = try? Api_BookmarkRequest().serializedData() else {
            failed("Could not create Api_BookmarkRequest")
            return
        }

        let (response, httpStatus) = postToServer(url: url, token: token, data: data)

        guard let response, httpStatus == ServerConstants.HttpConstants.ok else {
            failed("Retrieve bookmarks received an invalid response: Status: \(httpStatus) - Response: \(String(describing: (response as? NSData)))")

            return
        }

        parse(response: response)
    }

    private func parse(response: Data) {
        do {
            let bookmarksResponse = try Api_BookmarksResponse(serializedData: response)
            onBookmarksRetrieved(bookmarksResponse.bookmarks.nilIfEmpty())
        } catch {
            failed("Decoding BookmarksResponse failed \(error.localizedDescription)")
        }
    }

    private func failed(_ message: String) {
        FileLog.shared.addMessage(message)
        onBookmarksRetrieved(nil)
    }
}
