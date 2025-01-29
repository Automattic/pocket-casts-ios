import Foundation

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

    func checkIfNewEpisodesAreAvailable() async -> Bool {
        // Test implementation to simulate the API
        await MainActor.run {
            loadingState = .loading
        }
        _ = await shouldReloadPodcasts()

        try? await Task.sleep(nanoseconds: 3_000_000_000)

        await MainActor.run {
            Toast.show(L10n.podcastFeedReloadNoEpisodesFound)
        }
        await MainActor.run {
            loadingState = .idle
        }
        return false
    }

    private func shouldReloadPodcasts() async -> Int {
        await MainActor.run {
            Toast.show(L10n.podcastFeedReloadLoading)
        }
        return 202
    }

    private func pollUpdatePodcast() async { }
}
