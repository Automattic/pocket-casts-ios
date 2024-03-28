import Foundation
import PocketCastsServer
import PocketCastsUtils

class ShowNotesUpdater {
    class func updateShowNotesInBackground(podcastUuid: String, episodeUuid: String) {
        if FeatureFlag.newShowNotesEndpoint.enabled {
            Task {
                // Load the show notes and any available chapters
                _ = try? await ShowInfoCoordinator.shared.loadChapters(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
            }
            return
        }
        DispatchQueue.global().async {
            // fire and forgot, this call will automatically cache the result
            CacheServerHandler.shared.loadShowNotes(podcastUuid: podcastUuid, episodeUuid: episodeUuid, completion: nil)
        }
    }
}
