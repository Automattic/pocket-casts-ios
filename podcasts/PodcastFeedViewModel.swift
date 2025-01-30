import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

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
        guard let uuid, let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            return false
        }
        await MainActor.run {
            loadingState = .loading
            if source == .refreshControl {
                NotificationCenter.default.post(name: PodcastFeedReloadNotification.loading, object: nil)
            } else {
                Toast.show(L10n.podcastFeedReloadLoading)
            }
        }

        let success: Bool
        do {
            success = try await MainServerHandler.shared.updatePodcast(uuid: uuid, lastEpisodeUuid: podcast.latestEpisodeUuid)
        } catch {
            success = false
            FileLog.shared.console("Failed update podcast \(uuid) - \(error.localizedDescription)")
        }

        await MainActor.run {
            if source == .refreshControl {
                let notification = success ? PodcastFeedReloadNotification.episodesFound : PodcastFeedReloadNotification.noEpisodesFound
                NotificationCenter.default.post(name: notification, object: nil)
            } else {
                let message = success ? L10n.podcastFeedReloadNewEpisodesFound : L10n.podcastFeedReloadNoEpisodesFound
                Toast.show(message)
            }
            loadingState = .idle
        }
        return success
    }
}
