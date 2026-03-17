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
        var success = false
        dbQueue.write { db in
            do {
                try db.insert(
                    into: Self.tableName,
                    columns: ["timestamp", "episode_uuid", "podcast_uuid", "bytes_downloaded", "bytes_streamed", "bytes_uploaded", "operation_type", "connection_type", "session_type"],
                    values: [timestamp.timeIntervalSince1970, episodeUuid, podcastUuid, bytesDownloaded, bytesStreamed, bytesUploaded, operationType.rawValue, connectionType.rawValue, sessionType?.rawValue]
                )
                success = true
            } catch {}
        }
        return success
    }

    // MARK: - Cleanup

    @discardableResult
    public func deleteRecords(olderThan date: Date) async -> Bool {
        let before = date.timeIntervalSince1970
        return dbQueue.write { db in
            try NetworkDataUsageRecord.filter(NetworkDataUsageRecord.Columns.timestamp < before).deleteAll(db)
        }
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

    /// Derives a ``ConnectionType`` from URL session task metrics.
    /// Returns `.unknown` when no transaction metrics are available.
    public static func connectionType(from metrics: URLSessionTaskMetrics) -> ConnectionType {
        guard !metrics.transactionMetrics.isEmpty else {
            return .unknown
        }

        if metrics.transactionMetrics.contains(where: { $0.isCellular }) {
            return .cellular
        }

        return .wifi
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
