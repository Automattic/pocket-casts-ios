import Foundation
import PocketCastsServer
import PocketCastsUtils

class ShowNotesUpdater {
    class func updateShowNotesInBackground(podcastUuid: String, episodeUuid: String) {
        if FeatureFlag.newShowNotesEndpoint.enabled {
            Task {
                // Load the show notes and any available chapters
                _ = try? await ShowInfoCoordinator.shared.loadChapters(podcastUuid: podcastUuid, episodeUuid: episodeUuid)

                #if !os(watchOS)
                if FeatureFlag.transcripts.enabled {
                    let transcriptManager = TranscriptManager(episodeUUID: episodeUuid, podcastUUID: podcastUuid)
                    _ = try? await transcriptManager.loadTranscript()
                }
                #endif
            }
            return
        }

        DispatchQueue.global().async {
            // fire and forgot, this call will automatically cache the result
            CacheServerHandler.shared.loadShowNotes(podcastUuid: podcastUuid, episodeUuid: episodeUuid, completion: nil)
        }
    }
}
