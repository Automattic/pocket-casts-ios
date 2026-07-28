import Foundation
import PocketCastsUtils

public enum UpNextComparisonResult: Int {
    case same
    case phoneNeedsUpdate
    case watchNeedsUpdate
    case notEnoughInformation
}

public struct UpNextListComparator {
    public static func compare(phoneEpisodes: [BaseEpisode]?,
                               phoneUpNextCount: Int,
                               watchEpisodes: [BaseEpisode],
                               watchEpisodeCount: Int,
                               lastServerRefresh: Date?,
                               lastWatchDataTime: Date,
                               useConservativeComparison: Bool = true) -> UpNextComparisonResult {
        guard let phoneEpisodes, !phoneEpisodes.isEmpty else {
            if watchEpisodeCount == 0 {
                return .same
            } else {
                return .phoneNeedsUpdate
            }
        }

        if phoneUpNextCount > phoneEpisodes.count {
            return .notEnoughInformation
        }

        if phoneEpisodes.count == watchEpisodes.count {
            if watchEpisodes.isEmpty {
                return .same
            }

            var allMatch = true
            for (index, episode) in watchEpisodes.enumerated() {
                if episode.uuid != phoneEpisodes[index].uuid {
                    allMatch = false
                    break
                }
            }

            if allMatch {
                return .same
            }
        }

        guard let lastServerRefresh else {
            if useConservativeComparison {
                FileLog.shared.addMessage("WatchSyncManager: No lastServerRefresh timestamp, returning .notEnoughInformation")
                return .notEnoughInformation
            } else {
                return .watchNeedsUpdate
            }
        }

        if lastServerRefresh > lastWatchDataTime {
            FileLog.shared.addMessage("WatchSyncManager: Phone data is newer (lastServerRefresh: \(lastServerRefresh) > lastDataTime: \(lastWatchDataTime)), returning .phoneNeedsUpdate")
            return .phoneNeedsUpdate
        } else if lastServerRefresh < lastWatchDataTime {
            FileLog.shared.addMessage("WatchSyncManager: Watch data is newer (lastServerRefresh: \(lastServerRefresh) < lastDataTime: \(lastWatchDataTime)), returning .watchNeedsUpdate")
            return .watchNeedsUpdate
        } else {
            if useConservativeComparison {
                FileLog.shared.addMessage("WatchSyncManager: Timestamps are equal, returning .same")
                return .same
            } else {
                return .watchNeedsUpdate
            }
        }
    }
}

public struct WatchSyncDecision {
    public static func shouldPerformBackgroundRefresh(isPlusUser: Bool,
                                                      isAppInBackground: Bool,
                                                      comparisonResult: UpNextComparisonResult,
                                                      isFirstSyncInProgress: Bool) -> Bool {
        isPlusUser && isAppInBackground && comparisonResult == .watchNeedsUpdate && !isFirstSyncInProgress
    }
}
