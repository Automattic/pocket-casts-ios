import PocketCastsDataModel

extension Episode {
    func checkTranscriptAvailability() {
        Task.init {
            if let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: parentIdentifier(), episodeUuid: uuid) {
                let transcriptsAvailable = !transcripts.isEmpty
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeTranscriptAvailabilityChanged, userInfo: ["episodeUuid": uuid, "isAvailable": transcriptsAvailable])
            }
        }
    }
}
