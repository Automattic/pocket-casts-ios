import PocketCastsDataModel

extension Episode {
    func checkTranscriptAvailability() {
        Task.init {
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
