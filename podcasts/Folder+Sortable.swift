import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension Folder: @retroactive Sortable {
    public var itemUUID: String {
        uuid
    }

    public var itemTitle: String? {
        name
    }
}
