import Combine
import PocketCastsDataModel

/// Coordinates playlist cache invalidation in response to episode changes.
/// Subscribes to episode change notifications, determines which playlists are affected,
/// and triggers stale marking with debounced refresh.
final class PlaylistCacheInvalidationCoordinator {

    private let playlistMetadataLoader: PlaylistMetadataLoader
    private let dataManager: DataManager
    private var notificationObservers: [NSObjectProtocol] = []

    /// Subject for debouncing change processing
    private let changeSubject = PassthroughSubject<Void, Never>()
    private var debounceCancellable: AnyCancellable?

    /// Pending changes to coalesce before processing
    private var pendingChanges: [(changeType: EpisodeChangeType, podcastUuid: String?)] = []
    private let pendingChangesLock = NSLock()

    init(
        playlistMetadataLoader: PlaylistMetadataLoader,
        dataManager: DataManager = .sharedManager,
        debounceDelay: TimeInterval = 0.3
    ) {
        self.playlistMetadataLoader = playlistMetadataLoader
        self.dataManager = dataManager

        debounceCancellable = changeSubject
            .debounce(for: .seconds(debounceDelay), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.processPendingChanges()
            }
    }

    deinit {
        stopObserving()
    }

    /// Starts observing episode change notifications.
    func startObserving() {
        guard notificationObservers.isEmpty else { return }

        let center = NotificationCenter.default

        // Play status changes
        notificationObservers.append(
            center.addObserver(
                forName: Constants.Notifications.episodePlayStatusChanged,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                let podcastUuid = self?.extractPodcastUuid(from: notification)
                self?.handleChange(.playStatus, podcastUuid: podcastUuid)
            }
        )

        // Download status changes
        notificationObservers.append(
            center.addObserver(
                forName: Constants.Notifications.episodeDownloadStatusChanged,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                let podcastUuid = self?.extractPodcastUuid(from: notification)
                self?.handleChange(.downloadStatus, podcastUuid: podcastUuid)
            }
        )

        // Starred status changes
        notificationObservers.append(
            center.addObserver(
                forName: Constants.Notifications.episodeStarredChanged,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                let podcastUuid = self?.extractPodcastUuid(from: notification)
                self?.handleChange(.starred, podcastUuid: podcastUuid)
            }
        )

        // Archive status changes
        notificationObservers.append(
            center.addObserver(
                forName: Constants.Notifications.episodeArchiveStatusChanged,
                object: nil,
                queue: nil
            ) { [weak self] notification in
                let podcastUuid = self?.extractPodcastUuid(from: notification)
                self?.handleChange(.archived, podcastUuid: podcastUuid)
            }
        )

        // Bulk changes (many episodes changed)
        notificationObservers.append(
            center.addObserver(
                forName: Constants.Notifications.manyEpisodesChanged,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.handleChange(.bulkChange, podcastUuid: nil)
            }
        )
    }

    /// Stops observing episode change notifications.
    func stopObserving() {
        let center = NotificationCenter.default
        notificationObservers.forEach { center.removeObserver($0) }
        notificationObservers.removeAll()
    }

    // MARK: - Private

    private func handleChange(_ changeType: EpisodeChangeType, podcastUuid: String?) {
        pendingChangesLock.lock()
        pendingChanges.append((changeType, podcastUuid))
        pendingChangesLock.unlock()

        changeSubject.send()
    }

    private func processPendingChanges() {
        pendingChangesLock.lock()
        let changes = pendingChanges
        pendingChanges.removeAll()
        pendingChangesLock.unlock()

        guard !changes.isEmpty else { return }

        // Check if any change is a bulk change - if so, mark all stale
        if changes.contains(where: { $0.changeType == .bulkChange }) {
            Task {
                await playlistMetadataLoader.markAllStale()
            }
            return
        }

        // Fetch all playlists to check against
        let playlists = dataManager.allPlaylists(includeDeleted: false)

        // Group changes by type and collect unique podcast UUIDs
        var changesByType: [EpisodeChangeType: Set<String>] = [:]
        for (changeType, podcastUuid) in changes {
            if changesByType[changeType] == nil {
                changesByType[changeType] = []
            }
            if let uuid = podcastUuid {
                changesByType[changeType]?.insert(uuid)
            }
        }

        // Process each change type
        Task {
            for (changeType, podcastUuids) in changesByType {
                if podcastUuids.isEmpty {
                    // No specific podcast, check all
                    await playlistMetadataLoader.markStaleIfAffected(
                        by: changeType,
                        podcastUuid: nil,
                        playlists: playlists
                    )
                } else {
                    // Check each podcast
                    for podcastUuid in podcastUuids {
                        await playlistMetadataLoader.markStaleIfAffected(
                            by: changeType,
                            podcastUuid: podcastUuid,
                            playlists: playlists
                        )
                    }
                }
            }
        }
    }

    /// Extracts the podcast UUID from an episode notification.
    /// Notifications typically pass the episode UUID as the object.
    private func extractPodcastUuid(from notification: Notification) -> String? {
        guard let episodeUuid = notification.object as? String else {
            return nil
        }

        // Look up the episode to get its podcast UUID
        guard let episode = dataManager.findEpisode(uuid: episodeUuid) else {
            return nil
        }

        return episode.podcastUuid
    }
}
