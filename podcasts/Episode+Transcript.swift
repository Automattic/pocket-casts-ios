import PocketCastsDataModel
import PocketCastsUtils

extension Episode {
    func checkTranscriptAvailability() {
        Task.init {
            let metadata = try? await ShowInfoCoordinator.shared.loadTranscriptsMetadata(podcastUuid: parentIdentifier(), episodeUuid: uuid)

            let transcriptsAvailable: Bool
            let hasGeneratedTranscripts: Bool

            #if DEBUG
            if FeatureFlag.syncedTranscripts.enabled {
                transcriptsAvailable = true
                hasGeneratedTranscripts = metadata?.hasGeneratedTranscripts ?? false
            } else {
                guard let metadata else { return }
                transcriptsAvailable = !metadata.transcripts.isEmpty
                hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
            }
            #else
            guard let metadata else { return }
            transcriptsAvailable = !metadata.transcripts.isEmpty
            hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
            #endif

            let userInfo: [AnyHashable: Any] = [
                "episodeUuid": uuid,
                "isAvailable": transcriptsAvailable,
                "hasGeneratedTranscripts": hasGeneratedTranscripts
            ]
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeTranscriptAvailabilityChanged, userInfo: userInfo)
        }
    }
}
