import Foundation
import PocketCastsServer

extension Error {
    /// A user-facing, localized message suitable for surfacing in the UI (e.g.
    /// a toast or an error state). Errors we recognise are mapped to dedicated
    /// localized copy; anything else falls back to the system description.
    var localizedMessage: String {
        switch self {
        case is HistorySyncError:
            return L10n.refreshFailed
        default:
            return localizedDescription
        }
    }
}
