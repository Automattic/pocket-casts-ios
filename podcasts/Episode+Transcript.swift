import PocketCastsDataModel
import PocketCastsUtils

extension Episode {
    func checkTranscriptAvailability() {
        Task {
            if let metadata = try? await ShowInfoCoordinator.shared.loadTranscriptsMetadata(podcastUuid: parentIdentifier(), episodeUuid: uuid) {
                let transcriptsAvailable = !metadata.transcripts.isEmpty
                let hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
                let userInfo = [
                    "episodeUuid": uuid,
                    "isAvailable": transcriptsAvailable,
                    "hasGeneratedTranscripts": hasGeneratedTranscripts
                ]
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeTranscriptAvailabilityChanged, userInfo: userInfo)
            }
        }
    }
}
