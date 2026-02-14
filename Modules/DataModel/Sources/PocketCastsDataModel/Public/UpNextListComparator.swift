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
                               lastLocalQueueChange: Date? = nil,
                               useConservativeComparison: Bool = true) -> UpNextComparisonResult {
        // Handle nil (no phone context received yet) vs empty (phone intentionally sent empty queue)
        guard let phoneEpisodes = phoneEpisodes else {
            // No phone context received - we don't have enough info to make a decision
            if watchEpisodeCount == 0 {
                return .same
            } else {
                FileLog.shared.addMessage("WatchSyncManager: No phone context received but watch has \(watchEpisodeCount) episodes - Not enough information")
                return .notEnoughInformation
            }
        }

        guard phoneEpisodes.count > 0 else {
            if watchEpisodeCount == 0 {
                return .same
            } else {
                // Phone explicitly sent empty queue - this is intentional (user cleared queue on phone)
                // Watch should update FROM phone, not push stale data TO server
                FileLog.shared.addMessage("WatchSyncManager: Phone sent empty queue but watch has \(watchEpisodeCount) episodes - Watch needs update")
                return .watchNeedsUpdate
            }
        }

        if phoneUpNextCount > phoneEpisodes.count {
            return .notEnoughInformation
        }

        if phoneEpisodes.count == watchEpisodes.count {
            if watchEpisodes.count == 0 {
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

        guard let lastServerRefresh = lastServerRefresh else {
            if useConservativeComparison {
                FileLog.shared.addMessage("WatchSyncManager: No lastServerRefresh timestamp, returning .notEnoughInformation")
                return .notEnoughInformation
            } else {
                return .watchNeedsUpdate
            }
        }

        // Check if Watch made local queue changes AFTER receiving the latest phone data.
        // If so, those local changes should sync to the server.
        if let localChange = lastLocalQueueChange, localChange > lastWatchDataTime {
            FileLog.shared.addMessage("WatchSyncManager: Local queue change (\(localChange)) is newer than phone data (\(lastWatchDataTime)), returning .phoneNeedsUpdate")
            return .phoneNeedsUpdate
        }

        // No local changes after phone data - phone is source of truth
        FileLog.shared.addMessage("WatchSyncManager: No local changes after phone data, returning .watchNeedsUpdate (phone is source of truth)")
        return .watchNeedsUpdate
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
