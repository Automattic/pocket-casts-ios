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
        case cancelled
    }

    let uuid: String?

    private(set) var loadingState: LoadingState = .idle
    private var podcastFeedReloadTask: Task<Bool, Never>?

    init(uuid: String?) {
        self.uuid = uuid
    }

    func cancelTask() {
        if loadingState == .loading,
           let task = podcastFeedReloadTask,
           !task.isCancelled {
            loadingState = .cancelled
            task.cancel()
        }
    }

    func checkIfNewEpisodesAreAvailable(from source: PodcastFeedReloadSource) async -> Bool {
        guard let uuid, let podcast = DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true) else {
            return false
        }
        podcastFeedReloadTask = Task { [weak self] in
            guard let self else { return false }
            await MainActor.run {
                self.loadingState = .loading
                if source == .refreshControl {
                    NotificationCenter.default.post(name: PodcastFeedReloadNotification.loading, object: nil)
                } else {
                    Toast.show(L10n.podcastFeedReloadLoading, dismissAfter: .never)
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
                if self.loadingState != .cancelled {
                    if source == .refreshControl {
                        let notification = success ? PodcastFeedReloadNotification.episodesFound : PodcastFeedReloadNotification.noEpisodesFound
                        NotificationCenter.default.post(name: notification, object: nil)
                    } else {
                        let message = success ? L10n.podcastFeedReloadNewEpisodesFound : L10n.podcastFeedReloadNoEpisodesFound
                        Toast.show(message)
                    }
                }
                self.loadingState = .idle
            }
            return success
        }
        return await podcastFeedReloadTask?.value ?? false
    }
}
