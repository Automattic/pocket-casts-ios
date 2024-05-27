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
            } catch {
                FileLog.shared.addMessage("UpNextHistoryManager.snapshot error: \(error)")
            }
        }
    }

    /// Return all the available Up Next entries
    func entries(dbQueue: FMDatabaseQueue) -> [Date] {
        var entries: [Date] = []
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT COUNT(*), date FROM PlaylistEpisodeHistory GROUP BY (date)", values: nil)
                defer { resultSet.close() }

                while resultSet.next(), let date = resultSet.date(forColumn: "date") {
                    entries.append(date)
                }
            } catch {
                FileLog.shared.addMessage("UpNextHistoryManager.entries error: \(error)")
            }
        }

        return entries
    }
}
