import PocketCastsUtils
import Foundation
import GRDB

public struct NetworkDataUsageManager {
    static let tableName = "NetworkDataUsage"
    private let dbQueue: GRDBQueue

    init(dbQueue: GRDBQueue) {
        self.dbQueue = dbQueue
    }

    // MARK: - Adding

    @discardableResult
    public func add(
        episodeUuid: String? = nil,
        podcastUuid: String? = nil,
        bytesDownloaded: Int64 = 0,
        bytesStreamed: Int64 = 0,
        bytesUploaded: Int64 = 0,
        operationType: OperationType,
        connectionType: ConnectionType,
        sessionType: SessionType? = nil,
        timestamp: Date = Date()
    ) -> Bool {
        var record = NetworkDataUsageRecord()
        record.timestamp = timestamp.timeIntervalSince1970
        record.episodeUuid = episodeUuid
        record.podcastUuid = podcastUuid
        record.bytesDownloaded = bytesDownloaded
        record.bytesStreamed = bytesStreamed
        record.bytesUploaded = bytesUploaded
        record.operationType = operationType.rawValue
        record.connectionType = Int32(connectionType.rawValue)
        record.sessionType = sessionType?.rawValue

        return dbQueue.insert(&record)
    }

    // MARK: - Retrieving

    public func totalDataUsage(since date: Date, connectionType: ConnectionType? = nil) -> Int64 {
        let since = date.timeIntervalSince1970

        let result: Int64? = dbQueue.read { db in
            var request = NetworkDataUsageRecord
                .filter(NetworkDataUsageRecord.Columns.timestamp >= since)

            if let connectionType {
                request = request.filter(NetworkDataUsageRecord.Columns.connectionType == connectionType.rawValue)
            }

            let downloaded = request.select(sum(NetworkDataUsageRecord.Columns.bytesDownloaded))
            let streamed = request.select(sum(NetworkDataUsageRecord.Columns.bytesStreamed))
            let uploaded = request.select(sum(NetworkDataUsageRecord.Columns.bytesUploaded))

            let downloadedTotal: Int64 = try Int64.fetchOne(db, downloaded) ?? 0
            let streamedTotal: Int64 = try Int64.fetchOne(db, streamed) ?? 0
            let uploadedTotal: Int64 = try Int64.fetchOne(db, uploaded) ?? 0

            return downloadedTotal + streamedTotal + uploadedTotal
        }

        return result ?? 0
    }

    public func totalCellularDataUsage(since date: Date) -> Int64 {
        totalDataUsage(since: date, connectionType: .cellular)
    }

    public func dataUsageByOperation(since date: Date, connectionType: ConnectionType? = nil) -> [OperationType: Int64] {
        let since = date.timeIntervalSince1970

        struct OperationTotal: Decodable, FetchableRecord {
            let operationType: String
            let total: Int64

            enum CodingKeys: String, CodingKey {
                case operationType = "operation_type"
                case total
            }
        }

        let result: [OperationType: Int64]? = dbQueue.read { db in
            var request = NetworkDataUsageRecord
                .filter(NetworkDataUsageRecord.Columns.timestamp >= since)

            if let connectionType {
                request = request.filter(NetworkDataUsageRecord.Columns.connectionType == connectionType.rawValue)
            }

            // Sum the byte columns and add them together
            // Using SQL literal for the COALESCE(SUM(...), 0) pattern
            let totalExpression = SQL("""
                COALESCE(SUM(\(NetworkDataUsageRecord.Columns.bytesDownloaded)), 0) + \
                COALESCE(SUM(\(NetworkDataUsageRecord.Columns.bytesStreamed)), 0) + \
                COALESCE(SUM(\(NetworkDataUsageRecord.Columns.bytesUploaded)), 0)
                """).sqlExpression

            let groupedRequest = request
                .select(
                    NetworkDataUsageRecord.Columns.operationType,
                    totalExpression.forKey("total")
                )
                .group(NetworkDataUsageRecord.Columns.operationType)

            let rows = try OperationTotal.fetchAll(db, groupedRequest)

            var results: [OperationType: Int64] = [:]
            for row in rows {
                if let opType = OperationType(rawValue: row.operationType) {
                    let normalizedOpType = normalizedOperationType(opType)
                    results[normalizedOpType, default: 0] += row.total
                }
            }
            return results
        }

        return result ?? [:]
    }

    public func cellularDataUsageByOperation(since date: Date) -> [OperationType: Int64] {
        dataUsageByOperation(since: date, connectionType: .cellular)
    }

    public struct WeeklyUsage {
        public let weekStartDate: Date
        public let totalBytes: Int64
    }

    public struct WeeklyUsageByType {
        public let weekStartDate: Date
        public let bytesByType: [OperationType: Int64]

        public var totalBytes: Int64 {
            bytesByType.values.reduce(0, +)
        }
    }

    public func weeklyDataUsageByType(forWeeks numberOfWeeks: Int, connectionType: ConnectionType? = .cellular) -> [WeeklyUsageByType] {
        let calendar = Calendar.current

        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }

        var weekRanges: [(start: Date, end: Date)] = []
        for weekOffset in (0..<numberOfWeeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }
            weekRanges.append((start: weekStart, end: weekEnd))
        }

        guard let oldestWeekStart = weekRanges.first?.start else {
            return []
        }

        struct RecordRow: Decodable, FetchableRecord {
            let timestamp: Double
            let operationType: String
            let total: Int64

            enum CodingKeys: String, CodingKey {
                case timestamp
                case operationType = "operation_type"
                case total
            }
        }

        let result: [WeeklyUsageByType]? = dbQueue.read { db in
            var request = NetworkDataUsageRecord
                .filter(NetworkDataUsageRecord.Columns.timestamp >= oldestWeekStart.timeIntervalSince1970)

            if let connectionType {
                request = request.filter(NetworkDataUsageRecord.Columns.connectionType == connectionType.rawValue)
            }

            // Columns are NOT NULL DEFAULT 0, so no COALESCE needed
            let totalExpression = NetworkDataUsageRecord.Columns.bytesDownloaded +
                                  NetworkDataUsageRecord.Columns.bytesStreamed +
                                  NetworkDataUsageRecord.Columns.bytesUploaded

            let orderedRequest = request
                .select(
                    NetworkDataUsageRecord.Columns.timestamp,
                    NetworkDataUsageRecord.Columns.operationType,
                    totalExpression.forKey("total")
                )
                .order(NetworkDataUsageRecord.Columns.timestamp)

            let rows = try RecordRow.fetchAll(db, orderedRequest)

            var weekTotals: [Date: [OperationType: Int64]] = [:]
            for range in weekRanges {
                weekTotals[range.start] = [:]
            }

            for row in rows {
                let recordDate = Date(timeIntervalSince1970: row.timestamp)
                guard let opType = OperationType(rawValue: row.operationType) else {
                    continue
                }

                let normalizedOpType = normalizedOperationType(opType)

                for range in weekRanges {
                    if recordDate >= range.start && recordDate < range.end {
                        weekTotals[range.start, default: [:]][normalizedOpType, default: 0] += row.total
                        break
                    }
                }
            }

            return weekRanges.map { range in
                WeeklyUsageByType(weekStartDate: range.start, bytesByType: weekTotals[range.start] ?? [:])
            }
        }

        return result ?? []
    }

    public func weeklyDataUsage(forWeeks numberOfWeeks: Int, connectionType: ConnectionType? = .cellular) -> [WeeklyUsage] {
        let calendar = Calendar.current

        // Calculate week boundaries starting from the beginning of the current week
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }

        var weekRanges: [(start: Date, end: Date)] = []
        for weekOffset in (0..<numberOfWeeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }
            weekRanges.append((start: weekStart, end: weekEnd))
        }

        guard let oldestWeekStart = weekRanges.first?.start else {
            return []
        }

        struct RecordRow: Decodable, FetchableRecord {
            let timestamp: Double
            let total: Int64
        }

        let result: [WeeklyUsage]? = dbQueue.read { db in
            var request = NetworkDataUsageRecord
                .filter(NetworkDataUsageRecord.Columns.timestamp >= oldestWeekStart.timeIntervalSince1970)

            if let connectionType {
                request = request.filter(NetworkDataUsageRecord.Columns.connectionType == connectionType.rawValue)
            }

            // Columns are NOT NULL DEFAULT 0, so no COALESCE needed
            let totalExpression = NetworkDataUsageRecord.Columns.bytesDownloaded +
                                  NetworkDataUsageRecord.Columns.bytesStreamed +
                                  NetworkDataUsageRecord.Columns.bytesUploaded

            let orderedRequest = request
                .select(
                    NetworkDataUsageRecord.Columns.timestamp,
                    totalExpression.forKey("total")
                )
                .order(NetworkDataUsageRecord.Columns.timestamp)

            let rows = try RecordRow.fetchAll(db, orderedRequest)

            var weekTotals: [Date: Int64] = [:]
            for range in weekRanges {
                weekTotals[range.start] = 0
            }

            for row in rows {
                let recordDate = Date(timeIntervalSince1970: row.timestamp)

                for range in weekRanges {
                    if recordDate >= range.start && recordDate < range.end {
                        weekTotals[range.start, default: 0] += row.total
                        break
                    }
                }
            }

            return weekRanges.map { range in
                WeeklyUsage(weekStartDate: range.start, totalBytes: weekTotals[range.start] ?? 0)
            }
        }

        return result ?? []
    }

    // MARK: - Cleanup

    @discardableResult
    public func deleteRecords(olderThan date: Date) async -> Bool {
        let before = date.timeIntervalSince1970
        let filter = NetworkDataUsageRecord.Columns.timestamp < before
        let deletedCount = dbQueue.deleteAll(NetworkDataUsageRecord.self, filter: filter)
        return deletedCount >= 0
    }

    // MARK: - Enums

    public enum OperationType: String {
        case download // Legacy, kept for backward compatibility with existing data
        case stream
        case sync
        case upload
        case api
        case autoDownload
    }

    public enum ConnectionType: Int {
        case unknown = 0
        case wifi = 1
        case cellular = 2
    }

    public enum SessionType: String {
        case background
        case foreground
    }

    private func normalizedOperationType(_ operationType: OperationType) -> OperationType {
        switch operationType {
        case .autoDownload:
            return .download
        default:
            return operationType
        }
    }
}

// MARK: - Schema Creation
extension NetworkDataUsageManager {
    static func createTable(in db: PCDatabase) throws {
        try db.executeUpdate("""
            CREATE TABLE IF NOT EXISTS \(Self.tableName) (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL NOT NULL,
                episode_uuid TEXT,
                podcast_uuid TEXT,
                bytes_downloaded INTEGER NOT NULL DEFAULT 0,
                bytes_streamed INTEGER NOT NULL DEFAULT 0,
                bytes_uploaded INTEGER NOT NULL DEFAULT 0,
                operation_type TEXT NOT NULL,
                connection_type INTEGER NOT NULL,
                session_type TEXT
            );
        """, values: nil)

        try db.executeUpdate("CREATE INDEX IF NOT EXISTS network_data_timestamp ON \(Self.tableName) (timestamp);", values: nil)
        try db.executeUpdate("CREATE INDEX IF NOT EXISTS network_data_episode ON \(Self.tableName) (episode_uuid);", values: nil)
        try db.executeUpdate("CREATE INDEX IF NOT EXISTS network_data_connection ON \(Self.tableName) (connection_type);", values: nil)
    }
}
