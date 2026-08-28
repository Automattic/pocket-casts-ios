import Foundation
import GRDB

public class NetworkDataUsageRecord: NSObject {
    @objc public var id = 0 as Int64

    @objc public var timestamp = 0.0 as Double

    @objc public var episodeUuid: String?

    @objc public var podcastUuid: String?

    @objc public var bytesDownloaded = 0 as Int64

    @objc public var bytesStreamed = 0 as Int64

    @objc public var bytesUploaded = 0 as Int64

    @objc public var operationType = ""

    @objc public var connectionType = 0 as Int32

    @objc public var sessionType: String?

    override public init() {
        super.init()
    }

    // MARK: - GRDB

    public static let databaseTableName = "NetworkDataUsage"

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case episodeUuid = "episode_uuid"
        case podcastUuid = "podcast_uuid"
        case bytesDownloaded = "bytes_downloaded"
        case bytesStreamed = "bytes_streamed"
        case bytesUploaded = "bytes_uploaded"
        case operationType = "operation_type"
        case connectionType = "connection_type"
        case sessionType = "session_type"
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp) ?? 0.0
        episodeUuid = try container.decodeIfPresent(String.self, forKey: .episodeUuid)
        podcastUuid = try container.decodeIfPresent(String.self, forKey: .podcastUuid)
        bytesDownloaded = try container.decodeIfPresent(Int64.self, forKey: .bytesDownloaded) ?? 0
        bytesStreamed = try container.decodeIfPresent(Int64.self, forKey: .bytesStreamed) ?? 0
        bytesUploaded = try container.decodeIfPresent(Int64.self, forKey: .bytesUploaded) ?? 0
        operationType = try container.decodeIfPresent(String.self, forKey: .operationType) ?? ""
        connectionType = try container.decodeIfPresent(Int32.self, forKey: .connectionType) ?? 0
        sessionType = try container.decodeIfPresent(String.self, forKey: .sessionType)
    }

    public func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["timestamp"] = timestamp
        container["episode_uuid"] = episodeUuid
        container["podcast_uuid"] = podcastUuid
        container["bytes_downloaded"] = bytesDownloaded
        container["bytes_streamed"] = bytesStreamed
        container["bytes_uploaded"] = bytesUploaded
        container["operation_type"] = operationType
        container["connection_type"] = connectionType
        container["session_type"] = sessionType
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let timestamp = Column(CodingKeys.timestamp)
        public static let episodeUuid = Column(CodingKeys.episodeUuid)
        public static let podcastUuid = Column(CodingKeys.podcastUuid)
        public static let bytesDownloaded = Column(CodingKeys.bytesDownloaded)
        public static let bytesStreamed = Column(CodingKeys.bytesStreamed)
        public static let bytesUploaded = Column(CodingKeys.bytesUploaded)
        public static let operationType = Column(CodingKeys.operationType)
        public static let connectionType = Column(CodingKeys.connectionType)
        public static let sessionType = Column(CodingKeys.sessionType)
    }
}

extension NetworkDataUsageRecord: FetchableRecord, PersistableRecord, TableRecord, Decodable {}
