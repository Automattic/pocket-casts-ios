// Placeholder so that PlayEpisodeIntent can compile in widget extension, but never actually executes
// because it is a subclass of AudioPlaybackIntent which only runs in the app.
@available(iOS 17, *)
extension PlayEpisodeIntent {
    func intentPlayback(_ episodeUuid: String) {
        print("In Widget intent extension \(episodeUuid)")
    }
}
