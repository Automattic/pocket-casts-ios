import FMDB
import PocketCastsUtils

/// Calculates user End of Year stats
class EndOfYearDataManager {
    private let endPeriod = "2022-12-01"

    private lazy var listenedEpisodesThisYear = """
                                            lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', '2022-01-01') and strftime('%s', '\(endPeriod)')
                                           """

    /// If the user is eligible to see End of Year stats
    ///
    /// All it's needed is a single episode listened for more than 30 minutes.
    func isEligible(dbQueue: FMDatabaseQueue) -> Bool {
        var isEligible = false

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT playedUpTo from \(DataManager.episodeTableName)
                            WHERE
                            playedUpTo > 1800 AND
                            \(listenedEpisodesThisYear)
                            LIMIT 1
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    isEligible = true
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.listeningTime error: \(error)")
            }
        }

        return isEligible
    }

    /// Check if the user has the full listening history or not.
    ///
    /// This is not 100% accurated. In order to determine if the user
    /// has the full history we check for their latest episode listened.
    /// If this episode was interacted in 2021 or before, we assume they
    /// have the full history.
    /// If this is not true, we check for the total number of items of
    /// this year. If the number is small or equal 100, we assume they
    /// have the full history.
    func isFullListeningHistory(dbQueue: FMDatabaseQueue) -> Bool {
        var isFullListeningHistory = false

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT * from \(DataManager.episodeTableName)
                            WHERE
                            lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate < strftime('%s', '2022-01-01')
                            LIMIT 1
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    isFullListeningHistory = true
                } else {
                    isFullListeningHistory = numberOfItemsInListeningHistory(db: db) <= 100
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.isFullListeningHistory error: \(error)")
            }
        }

        return isFullListeningHistory
    }

    /// Returns the approximate listening time for the current year
    func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        var listeningTime: Double?

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT SUM(playedUpTo) as totalPlayedTime from \(DataManager.episodeTableName) WHERE \(listenedEpisodesThisYear)"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    listeningTime = resultSet.double(forColumn: "totalPlayedTime")
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.listeningTime error: \(error)")
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
                                \(listenedEpisodesThisYear)
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
                FileLog.shared.addMessage("EndOfYearDataManager.listenedCategories error: \(error)")
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
                                \(listenedEpisodesThisYear)
                            """

                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    let numberOfPodcasts = Int(resultSet.int(forColumn: "podcasts"))
                    let numberOfEpisodes = Int(resultSet.int(forColumn: "episodes"))
                    listenedNumbers = ListenedNumbers(numberOfPodcasts: numberOfPodcasts, numberOfEpisodes: numberOfEpisodes)
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.listenedNumbers error: \(error)")
            }
        }

        return listenedNumbers
    }

    /// Return the top podcasts ordered by number of played episodes
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
                                \(listenedEpisodesThisYear)
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
                FileLog.shared.addMessage("EndOfYearDataManager.topPodcasts error: \(error)")
            }
        }

        // If there's a tie on number of played episodes, check played time
        return allPodcasts.sorted(by: {
            if $0.numberOfPlayedEpisodes == $1.numberOfPlayedEpisodes {
                return $0.totalPlayedTime > $1.totalPlayedTime
            }
            return $0.numberOfPlayedEpisodes > $1.numberOfPlayedEpisodes
        })
    }

    /// Return the longest listened episode
    func longestEpisode(dbQueue: FMDatabaseQueue) -> Episode? {
        var episode: Episode?
        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT *
                            FROM \(DataManager.episodeTableName)
                            WHERE \(listenedEpisodesThisYear)
                            ORDER BY playedUpTo DESC
                            LIMIT 1
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    episode = Episode.from(resultSet: resultSet)
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.topPodcasts error: \(error)")
            }
        }

        return episode
    }

    private func numberOfItemsInListeningHistory(db: FMDatabase) -> Int {
        var numberOfItemsInListeningHistory = 0

        do {
            let query = """
                        SELECT COUNT(*) as total from \(DataManager.episodeTableName)
                        WHERE
                        \(listenedEpisodesThisYear)
                        LIMIT 1
                        """
            let resultSet = try db.executeQuery(query, values: nil)
            defer { resultSet.close() }

            if resultSet.next() {
                numberOfItemsInListeningHistory = Int(resultSet.int(forColumn: "total"))
            } else {

            }
        } catch {
            FileLog.shared.addMessage("EndOfYearDataManager.numberOfItemsInListeningHistory error: \(error)")
        }

        return numberOfItemsInListeningHistory
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
