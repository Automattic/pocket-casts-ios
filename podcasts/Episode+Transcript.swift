import PocketCastsDataModel
import PocketCastsUtils

extension Episode {
    func checkTranscriptAvailability() {
        Task.init {
            let metadata = try? await ShowInfoCoordinator.shared.loadTranscriptsMetadata(podcastUuid: parentIdentifier(), episodeUuid: uuid)

            guard let metadata else { return }
            let transcriptsAvailable = !metadata.transcripts.isEmpty
            let hasGeneratedTranscripts = metadata.hasGeneratedTranscripts

            let userInfo: [AnyHashable: Any] = [
                "episodeUuid": uuid,
                "isAvailable": transcriptsAvailable,
                "hasGeneratedTranscripts": hasGeneratedTranscripts
            ]
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeTranscriptAvailabilityChanged, userInfo: userInfo)
        }
    }
}
