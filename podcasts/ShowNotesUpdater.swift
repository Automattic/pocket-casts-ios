import Foundation
import PocketCastsServer

class ShowNotesUpdater {
    class func updateShowNotesInBackground(podcastUuid: String, episodeUuid: String) {
        DispatchQueue.global().async {
            // fire and forgot, this call will automatically cache the result
            CacheServerHandler.shared.loadShowNotes(podcastUuid: podcastUuid, episodeUuid: episodeUuid, completion: nil)
        }
    }
}
