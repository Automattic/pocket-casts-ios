import FMDB
import PocketCastsUtils

/// Calculates user End of Year stats
class EndOfYearDataManager {
    /// The date to start calculating results from
    /// The data will start from 00:00:00 (midnight) the users device time
    private let startDate = "2023-01-01"

    /// The date to stop including results from
    /// This is set to the day after the final day we want to include in the results to make sure we include the full
    /// day up to midnight
    private let endDate = "2024-01-01"

    private lazy var listenedEpisodesThisYear = """
                                            lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', '\(startDate)') and strftime('%s', '\(endDate)')
                                           """

    private lazy var listenedEpisodesPreviousYear = """
                                            lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', '2022-01-01') and strftime('%s', '2023-01-01')
                                           """

    /// If the user is eligible to see End of Year stats
    ///
    /// All it's needed is a single episode listened for more than 5 minutes.
    func isEligible(dbQueue: FMDatabaseQueue) -> Bool {
        var isEligible = false

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT playedUpTo from \(DataManager.episodeTableName)
                            WHERE
                            playedUpTo > 300 AND
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
    /// This is not 100% accurate. In order to determine if the user
    /// has the full history we check for their latest episode listened.
    /// If this episode was interacted in 2021 or before, we assume they
    /// have the full history.
    /// If this is not true, we check for the total number of items of
    /// this year. If the number is less than or equal 100, we assume they
    /// have the full history.
    func isFullListeningHistory(dbQueue: FMDatabaseQueue) -> Bool {
        var isFullListeningHistory = false

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT * from \(DataManager.episodeTableName)
                            WHERE
                            lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate < strftime('%s', '\(startDate)')
                            LIMIT 1
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    isFullListeningHistory = true
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.isFullListeningHistory error: \(error)")
            }
        }

        return isFullListeningHistory
    }

    /// Returns the number of episodes we have for this year
    func numberOfEpisodes(dbQueue: FMDatabaseQueue) -> Int {
        var numberOfEpisodes: Int = 0

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as numberOfEpisodes from \(DataManager.episodeTableName)
                            WHERE
                            \(listenedEpisodesThisYear)
                            """
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    numberOfEpisodes = Int(resultSet.int(forColumn: "numberOfEpisodes"))
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.numberOfEpisodes error: \(error)")
            }
        }

        return numberOfEpisodes
    }

    /// Returns the approximate listening time for the current year
    func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        var listeningTime: Double?

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT DISTINCT \(DataManager.episodeTableName).uuid, SUM(playedUpTo) as totalPlayedTime from \(DataManager.episodeTableName) WHERE \(listenedEpisodesThisYear)"
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
                            SELECT DISTINCT \(DataManager.episodeTableName).uuid,
                                COUNT(DISTINCT podcastUuid) as numberOfPodcasts,
                                COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as numberOfEpisodes,
                                SUM(playedUpTo) as totalPlayedTime,
                                \(DataManager.podcastTableName).*,
                                substr(trim(\(DataManager.podcastTableName).podcastCategory),1,instr(trim(\(DataManager.podcastTableName).podcastCategory)||char(10),char(10))-1) as category
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE \(DataManager.podcastTableName).uuid = \(DataManager.episodeTableName).podcastUuid and
                                \(listenedEpisodesThisYear) and
                            category IS NOT NULL and category != ''
                            GROUP BY category
                            ORDER BY totalPlayedTime DESC
"""

                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                while resultSet.next() {
                    let numberOfPodcasts = Int(resultSet.int(forColumn: "numberOfPodcasts"))
                    let numberOfEpisodes = Int(resultSet.int(forColumn: "numberOfEpisodes"))
                    let totalPlayedTime = resultSet.double(forColumn: "totalPlayedTime")
                    if let categoryTitle = resultSet.string(forColumn: "category") {
                        listenedCategories.append(ListenedCategory(
                            numberOfPodcasts: numberOfPodcasts,
                            categoryTitle: categoryTitle,
                            mostListenedPodcast: Podcast.from(resultSet: resultSet),
                            totalPlayedTime: totalPlayedTime,
                            numberOfEpisodes: numberOfEpisodes)
                        )
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
        var listenedNumbers = ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as episodes,
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
                            SELECT DISTINCT \(DataManager.episodeTableName).uuid,
                                SUM(playedUpTo) as totalPlayedTime,
                                COUNT(\(DataManager.episodeTableName).id) as played_episodes,
                                \(DataManager.podcastTableName).*
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE `\(DataManager.podcastTableName)`.uuid = `\(DataManager.episodeTableName)`.podcastUuid and
                                \(listenedEpisodesThisYear)
                            GROUP BY podcastUuid
                            ORDER BY totalPlayedTime DESC
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

        // If there's a tie on total played time, check number of played episodes
        return allPodcasts.sorted(by: {
            if $0.totalPlayedTime == $1.totalPlayedTime {
                return $0.numberOfPlayedEpisodes > $1.numberOfPlayedEpisodes
            }
            return $0.totalPlayedTime > $1.totalPlayedTime
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

    /// Given a list of UUIDs, return which UUIDs are present on the database
    func episodesThatExist(dbQueue: FMDatabaseQueue, uuids: [String]) -> [String] {
        var episodes: [String] = []

        dbQueue.inDatabase { db in
            do {
                let query = """
                            SELECT DISTINCT uuid FROM \(DataManager.episodeTableName) WHERE \(DataManager.episodeTableName).uuid IN \(DBUtils.valuesQuestionMarks(amount: uuids.count)) and
                                \(listenedEpisodesThisYear)
                            """
                let resultSet = try db.executeQuery(query, values: uuids)
                defer { resultSet.close() }

                while resultSet.next() {
                    if let uuid = resultSet.string(forColumn: "uuid") {
                        episodes.append(uuid)
                    }
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.episodesThatExist error: \(error)")
            }
        }

        return episodes
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

    /// Returns the approximate listening time for the current year
    func yearOverYearListeningTime(dbQueue: FMDatabaseQueue) -> YearOverYearListeningTime {
        var listeningTimeThisYear: Double = 0
        var listeningTimePreviousYear: Double = 0

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT DISTINCT \(DataManager.episodeTableName).uuid, SUM(playedUpTo) as totalPlayedTime from \(DataManager.episodeTableName) WHERE \(listenedEpisodesThisYear) UNION ALL SELECT DISTINCT \(DataManager.episodeTableName).uuid, SUM(playedUpTo) as totalPlayedTime from \(DataManager.episodeTableName) WHERE \(listenedEpisodesPreviousYear)"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    listeningTimeThisYear = resultSet.double(forColumn: "totalPlayedTime")
                }

                if resultSet.next() {
                    listeningTimePreviousYear = resultSet.double(forColumn: "totalPlayedTime")
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.listeningTime error: \(error)")
            }
        }

        return YearOverYearListeningTime(totalPlayedTimeThisYear: listeningTimeThisYear, totalPlayedTimeLastYear: listeningTimePreviousYear)
    }

    /// Returns the number of episodes started and finished
    /// The episode is considered completed if it was played at least 90%
    func episodesStartedAndCompleted(dbQueue: FMDatabaseQueue) -> EpisodesStartedAndCompleted {
        var started: Int = 0
        var completed: Int = 0

        dbQueue.inDatabase { db in
            do {
                let query = "SELECT COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as episodesPlayed from \(DataManager.episodeTableName) WHERE playingStatus = 3 OR playedUpTo >= 0.9 * duration AND \(listenedEpisodesThisYear) UNION SELECT COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as episodesPlayed from \(DataManager.episodeTableName) WHERE \(listenedEpisodesThisYear)"
                let resultSet = try db.executeQuery(query, values: nil)
                defer { resultSet.close() }

                if resultSet.next() {
                    completed = Int(resultSet.int(forColumn: "episodesPlayed"))
                }

                if resultSet.next() {
                    started = Int(resultSet.int(forColumn: "episodesPlayed"))
                }
            } catch {
                FileLog.shared.addMessage("EndOfYearDataManager.episodesStartedAndCompleted error: \(error)")
            }
        }

        return EpisodesStartedAndCompleted(started: started, completed: completed)
    }
}

public struct ListenedCategory {
    public let numberOfPodcasts: Int
    public var categoryTitle: String
    public let mostListenedPodcast: Podcast
    public let totalPlayedTime: Double
    public let numberOfEpisodes: Int

    public init(numberOfPodcasts: Int, categoryTitle: String, mostListenedPodcast: Podcast, totalPlayedTime: Double, numberOfEpisodes: Int) {
        self.numberOfPodcasts = numberOfPodcasts
        self.categoryTitle = categoryTitle
        self.mostListenedPodcast = mostListenedPodcast
        self.totalPlayedTime = totalPlayedTime
        self.numberOfEpisodes = numberOfEpisodes
        self.categoryTitle = simplifyCategoryName(categoryTitle)
    }

    private func simplifyCategoryName(_ category: String) -> String {
        switch category {
        case "Health & Fitness":
            "Health"
        case "Kids & Family":
            "Family"
        case "Religion & Spirituality":
            "Spirituality"
        case "Society & Culture":
            "Culture"
        default:
            category
        }
    }
}

public struct ListenedNumbers {
    public let numberOfPodcasts: Int
    public let numberOfEpisodes: Int

    public init(numberOfPodcasts: Int, numberOfEpisodes: Int) {
        self.numberOfPodcasts = numberOfPodcasts
        self.numberOfEpisodes = numberOfEpisodes
    }
}

public struct YearOverYearListeningTime {
    public let totalPlayedTimeThisYear: Double
    public let totalPlayedTimeLastYear: Double
    public let percentage: Double

    public init(totalPlayedTimeThisYear: Double, totalPlayedTimeLastYear: Double) {
        self.totalPlayedTimeThisYear = totalPlayedTimeThisYear
        self.totalPlayedTimeLastYear = totalPlayedTimeLastYear
        self.percentage = (((totalPlayedTimeThisYear - totalPlayedTimeLastYear) / totalPlayedTimeLastYear) * 100).rounded()
    }
}

public struct EpisodesStartedAndCompleted {
    public let started: Int
    public let completed: Int
    public let percentage: Double

    public init(started: Int, completed: Int) {
        self.started = max(started, completed)
        self.completed = completed
        self.percentage = (Double(completed) / Double(started)).clamped(to: 0..<1)
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
