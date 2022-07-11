import Foundation
import PocketCastsServer

class ShowNotesUpdater {
    class func updateShowNotesInBackground(episodeUuid: String) {
        DispatchQueue.global().async {
            // fire and forgot, this call will automatically cache the result
            CacheServerHandler.shared.loadShowNotes(episodeUuid: episodeUuid, completion: nil)
        }
    }
}
