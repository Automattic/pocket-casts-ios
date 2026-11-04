import Foundation
import PocketCastsUtils

/// Listening facts for Playback 2026. Uses the same "listened in year" definition as the
/// End of Year stats: an episode counts for the year of its last playback interaction.
class PlaybackStatsDataManager {
    private func listenedEpisodes(year: Int) -> String {
        "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate BETWEEN strftime('%s', '\(year)-01-01') AND strftime('%s', '\(year + 1)-01-01')"
    }

    /// Per-podcast listening time and distinct episodes played in the year, most listened first.
    func podcastStats(in year: Int, dbQueue: GRDBQueue) -> [PlaybackPodcastStats] {
        var stats: [PlaybackPodcastStats] = []

        dbQueue.read { db in
            do {
                let query = """
                            SELECT \(DataManager.podcastTableName).uuid as podcastUuid,
                                \(DataManager.podcastTableName).title as title,
                                \(DataManager.podcastTableName).author as author,
                                substr(trim(\(DataManager.podcastTableName).podcastCategory), 1, instr(trim(\(DataManager.podcastTableName).podcastCategory) || char(10), char(10)) - 1) as category,
                                SUM(\(DataManager.episodeTableName).playedUpTo) as playedSeconds,
                                COUNT(DISTINCT \(DataManager.episodeTableName).uuid) as episodesPlayed
                            FROM \(DataManager.episodeTableName), \(DataManager.podcastTableName)
                            WHERE \(DataManager.podcastTableName).uuid = \(DataManager.episodeTableName).podcastUuid AND
                                \(listenedEpisodes(year: year))
                            GROUP BY \(DataManager.podcastTableName).uuid
                            HAVING playedSeconds > 0
                            ORDER BY playedSeconds DESC
                            """
                let resultSet = try db.executeQuery(query, values: nil)

                while resultSet.next() {
                    guard let uuid = resultSet.string(forColumn: "podcastUuid") else { continue }
                    stats.append(PlaybackPodcastStats(
                        uuid: uuid,
                        title: resultSet.string(forColumn: "title") ?? "",
                        author: resultSet.string(forColumn: "author") ?? "",
                        genre: resultSet.string(forColumn: "category"),
                        playedSeconds: resultSet.double(forColumn: "playedSeconds"),
                        episodesPlayed: Int(resultSet.int(forColumn: "episodesPlayed"))
                    ))
                }
            } catch {
                FileLog.shared.addMessage("PlaybackStatsDataManager.podcastStats error: \(error)")
            }
        }

        return stats
    }

    /// Listening seconds per month of the year, January first. Always 12 entries.
    func monthlySeconds(in year: Int, dbQueue: GRDBQueue) -> [Double] {
        var months = [Double](repeating: 0, count: 12)

        dbQueue.read { db in
            do {
                let query = """
                            SELECT CAST(strftime('%m', lastPlaybackInteractionDate, 'unixepoch') AS INTEGER) as month,
                                SUM(playedUpTo) as playedSeconds
                            FROM \(DataManager.episodeTableName)
                            WHERE \(listenedEpisodes(year: year))
                            GROUP BY month
                            """
                let resultSet = try db.executeQuery(query, values: nil)

                while resultSet.next() {
                    let month = Int(resultSet.int(forColumn: "month"))
                    guard (1...12).contains(month) else { continue }
                    months[month - 1] = resultSet.double(forColumn: "playedSeconds")
                }
            } catch {
                FileLog.shared.addMessage("PlaybackStatsDataManager.monthlySeconds error: \(error)")
            }
        }

        return months
    }

    /// Distinct episodes listened to in the year, and how many of them were finished.
    func episodesStartedAndCompleted(in year: Int, dbQueue: GRDBQueue) -> (started: Int, completed: Int) {
        var started = 0
        var completed = 0

        dbQueue.read { db in
            do {
                let query = """
                            SELECT COUNT(DISTINCT uuid) as started,
                                COUNT(DISTINCT CASE WHEN playingStatus = 3 OR playedUpTo >= 0.9 * duration THEN uuid END) as completed
                            FROM \(DataManager.episodeTableName)
                            WHERE \(listenedEpisodes(year: year))
                            """
                let resultSet = try db.executeQuery(query, values: nil)

                if resultSet.next() {
                    started = Int(resultSet.int(forColumn: "started"))
                    completed = Int(resultSet.int(forColumn: "completed"))
                }
            } catch {
                FileLog.shared.addMessage("PlaybackStatsDataManager.episodesStartedAndCompleted error: \(error)")
            }
        }

        return (started, completed)
    }
}

public struct PlaybackPodcastStats {
    public let uuid: String
    public let title: String
    public let author: String
    /// The podcast's first category, if it has one.
    public let genre: String?
    public let playedSeconds: Double
    public let episodesPlayed: Int

    public init(uuid: String, title: String, author: String, genre: String?, playedSeconds: Double, episodesPlayed: Int) {
        self.uuid = uuid
        self.title = title
        self.author = author
        self.genre = genre
        self.playedSeconds = playedSeconds
        self.episodesPlayed = episodesPlayed
    }
}
