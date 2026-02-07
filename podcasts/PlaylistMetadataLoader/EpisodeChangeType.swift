/// Represents changes to an episode that may affect playlist membership
enum EpisodeChangeType {
    case playStatus      // Playing status changed (unplayed, in progress, played)
    case downloadStatus  // Download status changed
    case starred         // Starred/keep episode status changed
    case archived        // Archived status changed
    case deleted         // Episode was deleted
    case bulkChange      // Many episodes changed at once

    /// Returns all change types that could affect a playlist
    static var allCases: [EpisodeChangeType] {
        [.playStatus, .downloadStatus, .starred, .archived, .deleted, .bulkChange]
    }
}
