import Foundation
import GRDB
import PocketCastsUtils

/// GRDB QueryInterface-based implementations for AutoAddCandidatesDataManager.
/// These methods provide strongly-typed alternatives to the raw SQL queries.
/// Called from the main AutoAddCandidatesDataManager methods when the grdbQueryInterface feature flag is enabled.
extension AutoAddCandidatesDataManager {

    // MARK: - Update Methods using GRDB QueryInterface

    /// Add a candidate using GRDB QueryInterface
    func addGRDB(podcastUUID: String, episodeUUID: String, grdbQueue: GRDBQueue) {
        var record = AutoAddCandidateRecord()
        record.podcast_uuid = podcastUUID
        record.episode_uuid = episodeUUID

        _ = grdbQueue.write { db in
            try? record.insert(db)
        }
    }

    /// Remove a candidate using GRDB QueryInterface
    func removeGRDB(_ candidate: AutoAddCandidate, grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? AutoAddCandidateRecord
                .filter(AutoAddCandidateRecord.Columns.id == Int64(candidate.id))
                .limit(1)
                .deleteAll(db)
        }
    }

    /// Clear all candidates using GRDB QueryInterface
    func clearAllGRDB(grdbQueue: GRDBQueue) {
        _ = grdbQueue.write { db in
            try? AutoAddCandidateRecord.deleteAll(db)
        }
    }

    // Note: The candidates() method requires a complex JOIN query between
    // AutoAddCandidates and SJPodcast tables which is more efficiently
    // handled with raw SQL to access the podcast's autoAddToUpNext setting.
    // That method is intentionally left as raw SQL.
}
