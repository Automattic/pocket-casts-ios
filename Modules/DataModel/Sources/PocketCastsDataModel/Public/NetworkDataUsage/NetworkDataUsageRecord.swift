import Foundation
import GRDB
import GRDBMacros

@GRDBRecord(table: "NetworkDataUsage")
public class NetworkDataUsageRecord: NSObject {
    @objc public var id = 0 as Int64

    @objc public var timestamp = 0.0 as Double

    @GRDBColumn("episode_uuid")
    @objc public var episodeUuid: String?

    @GRDBColumn("podcast_uuid")
    @objc public var podcastUuid: String?

    @GRDBColumn("bytes_downloaded")
    @objc public var bytesDownloaded = 0 as Int64

    @GRDBColumn("bytes_streamed")
    @objc public var bytesStreamed = 0 as Int64

    @GRDBColumn("bytes_uploaded")
    @objc public var bytesUploaded = 0 as Int64

    @GRDBColumn("operation_type")
    @objc public var operationType = ""

    @GRDBColumn("connection_type")
    @objc public var connectionType = 0 as Int32

    @GRDBColumn("session_type")
    @objc public var sessionType: String?

    public override init() {
        super.init()
    }
}
