import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension Folder: Sortable {
    public var itemUUID: String {
        uuid
    }

    public var itemTitle: String? {
        name
    }
}
