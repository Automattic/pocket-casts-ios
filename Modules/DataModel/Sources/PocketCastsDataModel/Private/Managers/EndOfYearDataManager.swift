import FMDB
import PocketCastsUtils

/// Calculates user End of Year stats
class EndOfYearDataManager {

    /// Returns 5 random podcasts from the DB
    /// This is here for development purposes.
    func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        var listeningTime: Double?

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT SUM(playedUpTo) as totalPlayedTime from SJEpisode WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', date('now','start of year')) and strftime('%s', 'now')"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    listeningTime = resultSet.double(forColumn: "totalPlayedTime")
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.listeningTime error: \(error)")
            }
        }

        return listeningTime
    }

}
