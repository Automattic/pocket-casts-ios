import FMDB
import PocketCastsUtils

class UpNextHistoryManager {
    // MARK: - Queries

    /// Saves the current Up Next state into another table
    /// So it can be reverted later in case of wrong syncs
    func snapshot(dbQueue: FMDatabaseQueue) {
        dbQueue.inDatabase { db in
            do {
                try db.executeUpdate("INSERT INTO PlaylistEpisodeHistory SELECT *, ? as 'date' FROM SJPlaylistEpisode", values: [Date()])
                db.commit()
            } catch {
                FileLog.shared.addMessage("UpNextDataManager.save error: \(error)")
            }
        }
    }
}
