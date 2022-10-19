import FMDB
import PocketCastsUtils

/// Calculates user End of Year stats
class EndOfYearDataManager {
    private let endPeriod = "2022-12-01"

    /// Returns the aproximately listening time for the current year
    func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        var listeningTime: Double?

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT SUM(playedUpTo) as totalPlayedTime from \(DataManager.episodeTableName) WHERE lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', '2022-01-01') and strftime('%s', '\(endPeriod)')"
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

    /// Returns all the categories the user has listened to podcasts
    ///
    /// The returned array is ordered from the most listened to the least
    func listenedCategories(dbQueue: FMDatabaseQueue) -> [ListenedCategory] {
        var listenedCategories: [ListenedCategory] = []

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT COUNT(DISTINCT podcastUuid) as numberOfPodcasts,
                                SUM(playedUpTo) as totalPlayedTime,
                                replace(IFNULL( nullif(substr(\(DataManager.podcastTableName).podcastCategory, 0, INSTR(\(DataManager.podcastTableName).podcastCategory, char(10))), '') , \(DataManager.podcastTableName).podcastCategory), CHAR(10), '') as category
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE \(DataManager.podcastTableName).uuid = \(DataManager.episodeTableName).podcastUuid and
                                lastPlaybackInteractionDate IS NOT NULL AND
                                lastPlaybackInteractionDate BETWEEN strftime('%s', '2022-01-01') and strftime('%s', '\(endPeriod)')
                            GROUP BY category
                            ORDER BY totalPlayedTime DESC
"""

                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    let numberOfPodcasts = Int(resultSet.int(forColumn: "numberOfPodcasts"))
                    if let categoryTitle = resultSet.string(forColumn: "category") {
                        listenedCategories.append(ListenedCategory(numberOfPodcasts: numberOfPodcasts, categoryTitle: categoryTitle))
                    }
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.listenedCategories error: \(error)")
            }
        }

        return listenedCategories
    }

    /// Return the number of podcasts and episodes listened
    ///
    func listenedNumbers(dbQueue: FMDatabaseQueue) -> ListenedNumbers {
        var listenedNumbers: ListenedNumbers = ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT COUNT(\(DataManager.episodeTableName).id) as episodes,
                                COUNT(DISTINCT \(DataManager.podcastTableName).uuid) as podcasts
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE `\(DataManager.podcastTableName)`.uuid = `\(DataManager.episodeTableName)`.podcastUuid and
                                lastPlaybackInteractionDate IS NOT NULL AND
                                lastPlaybackInteractionDate BETWEEN strftime('%s', date('now','start of year')) and strftime('%s', 'now')
                            """

                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    let numberOfPodcasts = Int(resultSet.int(forColumn: "podcasts"))
                    let numberOfEpisodes = Int(resultSet.int(forColumn: "episodes"))
                    listenedNumbers = ListenedNumbers(numberOfPodcasts: numberOfPodcasts, numberOfEpisodes: numberOfEpisodes)
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.listenedNumbers error: \(error)")
            }
        }

        return listenedNumbers
    }

    /// Return the top podcasts ordered by listening time
    func topPodcasts(dbQueue: FMDatabaseQueue, limit: Int = 5) -> [TopPodcast] {
        var allPodcasts = [TopPodcast]()
        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT SUM(playedUpTo) as totalPlayedTime,
                                COUNT(\(DataManager.episodeTableName).id) as played_episodes,
                                \(DataManager.podcastTableName).*
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE `\(DataManager.podcastTableName)`.uuid = `\(DataManager.episodeTableName)`.podcastUuid and
                                lastPlaybackInteractionDate IS NOT NULL AND
                                lastPlaybackInteractionDate BETWEEN strftime('%s', '2022-01-01') and strftime('%s', '\(endPeriod)')
                            GROUP BY podcastUuid
                            ORDER BY played_episodes DESC
                            LIMIT \(limit)
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    let numberOfPlayedEpisodes = Int(resultSet.int(forColumn: "played_episodes"))
                    let totalPlayedTime = resultSet.double(forColumn: "totalPlayedTime")
                    allPodcasts.append(TopPodcast(podcast: Podcast.from(resultSet: resultSet), numberOfPlayedEpisodes: numberOfPlayedEpisodes, totalPlayedTime: totalPlayedTime))
                }
            } catch {
                FileLog.shared.addMessage("PodcastDataManager.topPodcasts error: \(error)")
            }
        }

        return allPodcasts
    }


}

public struct ListenedCategory {
    public let numberOfPodcasts: Int
    public let categoryTitle: String
}

public struct ListenedNumbers {
    public let numberOfPodcasts: Int
    public let numberOfEpisodes: Int

    public init(numberOfPodcasts: Int, numberOfEpisodes: Int) {
        self.numberOfPodcasts = numberOfPodcasts
        self.numberOfEpisodes = numberOfEpisodes
    }
}

public struct TopPodcast {
    public let podcast: Podcast
    public let numberOfPlayedEpisodes: Int
    public let totalPlayedTime: Double

    public init(podcast: Podcast, numberOfPlayedEpisodes: Int, totalPlayedTime: Double) {
        self.podcast = podcast
        self.numberOfPlayedEpisodes = numberOfPlayedEpisodes
        self.totalPlayedTime = totalPlayedTime
    }
}
