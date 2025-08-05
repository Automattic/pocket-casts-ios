import Foundation
import PocketCastsServer
import PocketCastsUtils

extension DiscoverItem {
    /// Attempts to infer the list ID for a discover item
    var inferredListId: String {
        // If the listId is set, then return that
        if let uuid {
            return uuid
        }

        guard let source else {
            return "none"
        }

        switch source {
        case _ where source.contains("trending"):
            return "trending"
        case _ where source.contains("popular"):
            return "popular"
        default:
            return "none"
        }
    }

    // Filter items for recommendations - authenticated items won't be included if logged out
    func shouldShowAuthenticated() -> Bool {
        if FeatureFlag.recommendations.enabled {
            if SyncManager.isUserLoggedIn() {
                return true
            } else {
                return authenticated != true // this handles both `false` and `nil` values
            }
        } else {
            return true
        }
    }
}
