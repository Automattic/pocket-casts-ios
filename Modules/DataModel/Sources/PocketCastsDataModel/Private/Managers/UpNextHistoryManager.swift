import FMDB
import PocketCastsUtils

public class UpNextHistoryManager {
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
    func entries(dbQueue: FMDatabaseQueue) -> [UpNextHistoryEntry] {
        var entries: [UpNextHistoryEntry] = []
        dbQueue.inDatabase { db in
            do {
                let resultSet = try db.executeQuery("SELECT COUNT(*) as count, date FROM PlaylistEpisodeHistory GROUP BY (date) ORDER BY date DESC", values: nil)
                defer { resultSet.close() }

                while resultSet.next(), let date = resultSet.date(forColumn: "date") {
                    entries.append(UpNextHistoryEntry(date: date, episodeCount: Int(resultSet.int(forColumn: "count"))))
                }
            } catch {
                FileLog.shared.addMessage("UpNextHistoryManager.entries error: \(error)")
            }
        }

        return entries
    }

    public struct UpNextHistoryEntry: Hashable, Identifiable {
        public var id: Date {
            date
        }

        public let date: Date
        public let episodeCount: Int
    }
}
