import Foundation
import PocketCastsDataModel

public extension PodcastNetworkList {
    /// Builds a network list out of the `network_list` object of a podcast refresh payload.
    ///
    /// The list source is derived from the list id when the payload doesn't carry one.
    init?(json: [String: Any]?) {
        guard let listId = json?["list_id"] as? String, !listId.isEmpty else {
            return nil
        }

        if let source = json?["source"] as? String, !source.isEmpty {
            self.init(listId: listId, source: source)
        } else {
            self.init(listId: listId, source: ServerHelper.listUrlString(listId: listId))
        }
    }
}
