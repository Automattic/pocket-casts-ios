/// Represents changes to an episode that may affect playlist membership
enum EpisodeChangeType: CaseIterable, Hashable, Sendable {
    case playStatus      // Playing status changed (unplayed, in progress, played)
    case downloadStatus  // Download status changed
    case starred         // Starred/keep episode status changed
    case archived        // Archived status changed
    case bulkChange      // Many episodes changed at once
}
