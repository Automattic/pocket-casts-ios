import FMDB
import GRDB
import PocketCastsUtils

public struct AutoAddCandidatesDataManager {
    private let dbQueue: FMDatabaseQueue
    private let dbPool: DatabasePool

    init(dbQueue: FMDatabaseQueue, dbPool: DatabasePool) {
        self.dbQueue = dbQueue
        self.dbPool = dbPool
    }

    /// Adds a new auto add candidate to the database
    public func add(podcastUUID: String, episodeUUID: String) {
        do {
            try dbPool.write { db in
                try db.execute(sql: "INSERT INTO \(Constants.tableName) (episode_uuid, podcast_uuid) VALUES (?, ?)", arguments: [episodeUUID, podcastUUID])
            }
        } catch {
            FileLog.shared.addMessage("AutoAddCandidatesDataManager.add error: \(error)")
        }
    }

    /// Removes a single candidate from the DB
    public func remove(_ candidate: AutoAddCandidate) {
        do {
            try dbPool.write { db in
                try db.execute(sql: """
                DELETE FROM \(Constants.tableName) WHERE id = ? LIMIT 1
                """, arguments: [candidate.id])
            }
        } catch {
            FileLog.shared.addMessage("AutoAddCandidatesDataManager.remove error: \(error)")
        }
    }

    /// Reset the the entire candidates table
    public func clearAll() {
        do {
            try dbPool.write { db in
                try db.execute(sql: "DELETE FROM \(Constants.tableName)")
            }
        } catch {
            FileLog.shared.addMessage("AutoAddCandidatesDataManager.clearAll error: \(error)")
        }
    }

    /// Returns the auto add up next candidates
    /// Each candidate contains the
    public func candidates() -> [AutoAddCandidate] {
        var results: [AutoAddCandidate] = []

        do {

            try dbPool.read { db in
                let query: String

                if FeatureFlag.newSettingsStorage.enabled {
                    query = """
                    SELECT
                        -- Get the Podcast Auto Add Setting
                        json_extract(podcast.settings, '$.addToUpNextPosition.value') AS \(Constants.autoAddSettingColumnName),

                        -- Get the episode UUID
                        queue.id AS \(Constants.idColumnName),
                        queue.episode_uuid AS \(Constants.episodeColumnName)
                    FROM
                        \(Constants.tableName) AS queue
                        JOIN \(DataManager.podcastTableName) AS podcast ON podcast.uuid = queue.podcast_uuid
                    -- Process the oldest items first
                    ORDER BY queue.id ASC
                    """
                } else {
                    query = """
                    SELECT
                        -- Get the Podcast Auto Add Setting
                        podcast.autoAddToUpNext AS \(Constants.autoAddSettingColumnName),

                        -- Get the episode UUID
                        queue.id AS \(Constants.idColumnName),
                        queue.episode_uuid AS \(Constants.episodeColumnName)
                    FROM
                        \(Constants.tableName) AS queue
                        JOIN \(DataManager.podcastTableName) AS podcast ON podcast.uuid = queue.podcast_uuid
                    -- Process the oldest items first
                    ORDER BY queue.id ASC
                    """
                }

                let rows = try Row.fetchCursor(db, sql: query)

                while let row = try rows.next() {
                    if let result = AutoAddCandidate(from: row) {
                        results.append(result)
                    }
                }
            }
        } catch {
            FileLog.shared.addMessage("candidates error: \(error)")
        }

        return results
    }

    // MARK: - Model

    /// The `AutoAddCandidate` represents an episode that could be auto added to the up next queue.
    /// To reduce the number of queries needed this also includes the related Podcast's auto add up next setting
    public struct AutoAddCandidate {
        let id: Int

        /// The Podcast.autoAddToUpNext setting value
        public let autoAddToUpNextSetting: AutoAddToUpNextSetting

        /// The UUID of the candidate episode to add
        public let episodeUuid: String

        init?(from resultSet: FMResultSet) {

            let setting: Int32
            if FeatureFlag.newSettingsStorage.enabled {
                let value = resultSet.int(forColumn: Constants.autoAddSettingColumnName)
                let position = UpNextPosition(rawValue: value)
                switch position {
                case .top:
                    setting = AutoAddToUpNextSetting.addFirst.rawValue
                case .bottom:
                    setting = AutoAddToUpNextSetting.addLast.rawValue
                default:
                    setting = AutoAddToUpNextSetting.off.rawValue
                }
            } else {
                setting = resultSet.int(forColumn: Constants.autoAddSettingColumnName)
            }

            guard
                let idObj = resultSet.object(forColumn: Constants.idColumnName) as? NSNumber,
                let episodeUuid = resultSet.string(forColumn: Constants.episodeColumnName),
                let autoAddSetting = AutoAddToUpNextSetting(rawValue: setting)
            else {
                return nil
            }

            self.id = idObj.intValue
            self.autoAddToUpNextSetting = autoAddSetting
            self.episodeUuid = episodeUuid
        }

        init?(from row: RowCursor.Element) {

            let setting: Int32
            if FeatureFlag.newSettingsStorage.enabled {
                let value: Int32 = row[Constants.autoAddSettingColumnName]
                let position = UpNextPosition(rawValue: value)
                switch position {
                case .top:
                    setting = AutoAddToUpNextSetting.addFirst.rawValue
                case .bottom:
                    setting = AutoAddToUpNextSetting.addLast.rawValue
                default:
                    setting = AutoAddToUpNextSetting.off.rawValue
                }
            } else {
                setting = row[Constants.autoAddSettingColumnName]
            }

            guard
                let idObj: NSNumber = row[Constants.idColumnName],
                let episodeUuid: String = row[Constants.episodeColumnName],
                let autoAddSetting = AutoAddToUpNextSetting(rawValue: setting)
            else {
                return nil
            }

            self.id = idObj.intValue
            self.autoAddToUpNextSetting = autoAddSetting
            self.episodeUuid = episodeUuid
        }
    }

    // MARK: - Config

    private enum Constants {
        static let tableName = "AutoAddCandidates"
        static let autoAddSettingColumnName = "auto_add_setting"
        static let settingsColumnName = "settings"
        static let episodeColumnName = "episode_uuid"
        static let idColumnName = "id"
    }
}
