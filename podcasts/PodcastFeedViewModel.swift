import Foundation

enum PodcastFeedReloadNotification {
    public static let loading = NSNotification.Name(rawValue: "PodcastFeedReloadNotificationLoading")
    public static let episodesFound = NSNotification.Name(rawValue: "PodcastFeedReloadNotificationEpisodesFound")
    public static let noEpisodesFound = NSNotification.Name(rawValue: "PodcastFeedReloadNotificationNoEpisodesFound")
}

class PodcastFeedViewModel {
    enum LoadingState {
        case idle
        case loading
    }

    let uuid: String?

    private(set) var loadingState: LoadingState = .idle

    init(uuid: String?) {
        self.uuid = uuid
    }

    func checkIfNewEpisodesAreAvailable(from source: PodcastFeedReloadSource) async -> Bool {
        // Test implementation to simulate the API
        await MainActor.run {
            loadingState = .loading
        }
        _ = await shouldReloadPodcasts(source: source)

        try? await Task.sleep(nanoseconds: 3_000_000_000)

        await MainActor.run {
            if source == .refreshControl {
                NotificationCenter.default.post(name: PodcastFeedReloadNotification.noEpisodesFound, object: nil)
            } else {
                Toast.show(L10n.podcastFeedReloadNoEpisodesFound)
            }
            loadingState = .idle
        }
        return false
    }

    private func shouldReloadPodcasts(source: PodcastFeedReloadSource) async -> Int {
        await MainActor.run {
            if source == .refreshControl {
                NotificationCenter.default.post(name: PodcastFeedReloadNotification.loading, object: nil)
            } else {
                Toast.show(L10n.podcastFeedReloadLoading)
            }
        }
        return 202
    }

    private func pollUpdatePodcast() async { }
}
