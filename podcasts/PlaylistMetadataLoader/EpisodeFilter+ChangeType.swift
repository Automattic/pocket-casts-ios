import PocketCastsDataModel

extension EpisodeFilter {

    /// Determines if this playlist could be affected by the given change type.
    /// For manual playlists, only bulk changes matter (full refresh).
    /// For smart playlists, checks if the change type matches any active filter criteria.
    ///
    /// - Parameter changeType: The type of episode change that occurred
    /// - Returns: true if the playlist might be affected by this change type
    func isAffected(by changeType: EpisodeChangeType) -> Bool {
        // Manual playlists are affected by bulk changes, deletions, and archiving
        // (since archived/deleted episodes are removed from the list)
        if manual {
            switch changeType {
            case .bulkChange, .deleted, .archived:
                return true
            case .playStatus, .downloadStatus, .starred:
                return false
            }
        }

        switch changeType {
        case .playStatus:
            // Affected if filtering by play status
            return filterUnplayed || filterPartiallyPlayed || filterFinished

        case .downloadStatus:
            // Affected if filtering by download status
            return filterDownloaded || filterNotDownloaded

        case .starred:
            // Affected if filtering by starred
            return filterStarred

        case .archived:
            // Affected if showing/hiding archived episodes
            // All playlists have some archive behavior
            return true

        case .deleted, .bulkChange:
            // Always affects all playlists
            return true
        }
    }

    /// Determines if this playlist could be affected by a change to the specified episode.
    /// Checks both the change type and whether the episode's podcast is included in this playlist.
    ///
    /// - Parameters:
    ///   - changeType: The type of episode change that occurred
    ///   - podcastUuid: The UUID of the podcast the episode belongs to
    /// - Returns: true if the playlist might be affected by this change
    func isAffected(by changeType: EpisodeChangeType, podcastUuid: String) -> Bool {
        // First check if the change type is relevant
        guard isAffected(by: changeType) else {
            return false
        }

        // For bulk changes, always affected
        if changeType == .bulkChange {
            return true
        }

        // If filtering all podcasts, this change could affect us
        if filterAllPodcasts {
            return true
        }

        // Check if the episode's podcast is in our list
        let podcasts = podcastUuids.components(separatedBy: ",")
        return podcasts.contains(podcastUuid)
    }
}
