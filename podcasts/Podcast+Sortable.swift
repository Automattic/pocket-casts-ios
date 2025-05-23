import Foundation
import PocketCastsDataModel
import PocketCastsUtils

extension Podcast: Sortable {
    public var itemUUID: String {
        uuid
    }

    public var itemTitle: String? {
        title
    }
}
