import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(GRDBMacrosPlugin)
import GRDBMacrosPlugin

let testMacros: [String: Macro.Type] = [
    "GRDBRecord": GRDBRecordMacro.self,
    "GRDBColumn": GRDBColumnMacro.self,
    "GRDBIgnore": GRDBIgnoreMacro.self,
]
#endif

// MARK: - NSObject Subclass Tests

/// Tests for the @GRDBRecord macro applied to NSObject subclasses.
/// Pattern used by: Episode, Podcast, Folder, EpisodeFilter
final class GRDBRecordNSObjectTests: XCTestCase {

    // MARK: - Basic NSObject Pattern (Episode-like)

    func testNSObjectWithTableName() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJEpisode")
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var title: String?
                @objc public var uuid = ""
            }
            """,
            expandedSource: """
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var title: String?
                @objc public var uuid = ""

                public static let databaseTableName = "SJEpisode"

                enum CodingKeys: String, CodingKey {
                    case id
                        case title
                        case uuid
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        title = try container.decodeIfPresent(String.self, forKey: .title)
                        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let title = Column(CodingKeys.title)
                        public static let uuid = Column(CodingKeys.uuid)
                }
            }

            extension Episode: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Complex NSObject (Podcast-like with many property types)

    func testNSObjectWithVariousPropertyTypes() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJPodcast")
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @objc public var addedDate: Date?
                @objc public var autoDownloadSetting = 0 as Int32
                @objc public var playbackSpeed = 1 as Double
                @objc public var boostVolume = false
                @objc public var title: String?
                @objc public var uuid = ""
            }
            """,
            expandedSource: """
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @objc public var addedDate: Date?
                @objc public var autoDownloadSetting = 0 as Int32
                @objc public var playbackSpeed = 1 as Double
                @objc public var boostVolume = false
                @objc public var title: String?
                @objc public var uuid = ""

                public static let databaseTableName = "SJPodcast"

                enum CodingKeys: String, CodingKey {
                    case id
                        case addedDate
                        case autoDownloadSetting
                        case playbackSpeed
                        case boostVolume
                        case title
                        case uuid
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
                        autoDownloadSetting = try container.decodeIfPresent(Int32.self, forKey: .autoDownloadSetting) ?? 0
                        playbackSpeed = try container.decodeIfPresent(Double.self, forKey: .playbackSpeed) ?? 1
                        boostVolume = try container.decodeIfPresent(Bool.self, forKey: .boostVolume) ?? false
                        title = try container.decodeIfPresent(String.self, forKey: .title)
                        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let addedDate = Column(CodingKeys.addedDate)
                        public static let autoDownloadSetting = Column(CodingKeys.autoDownloadSetting)
                        public static let playbackSpeed = Column(CodingKeys.playbackSpeed)
                        public static let boostVolume = Column(CodingKeys.boostVolume)
                        public static let title = Column(CodingKeys.title)
                        public static let uuid = Column(CodingKeys.uuid)
                }
            }

            extension Podcast: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - NSObject with @GRDBColumn (Podcast.autoArchiveEpisodeLimit pattern)

    func testNSObjectWithGRDBColumn() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJPodcast")
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @GRDBColumn("episodeKeepSetting")
                @objc public var autoArchiveEpisodeLimit = 0 as Int32
            }
            """,
            expandedSource: """
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @objc public var autoArchiveEpisodeLimit = 0 as Int32

                public static let databaseTableName = "SJPodcast"

                enum CodingKeys: String, CodingKey {
                    case id
                        case autoArchiveEpisodeLimit = "episodeKeepSetting"
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        autoArchiveEpisodeLimit = try container.decodeIfPresent(Int32.self, forKey: .autoArchiveEpisodeLimit) ?? 0
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let autoArchiveEpisodeLimit = Column(CodingKeys.autoArchiveEpisodeLimit)
                }
            }

            extension Podcast: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - NSObject with let property (EpisodeFilter.filterDownloading pattern)

    func testNSObjectWithLetProperty() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJFilteredPlaylist")
            public class EpisodeFilter: NSObject {
                @objc public var id = 0 as Int64
                @objc public let filterDownloading = true
                @objc public var filterFinished = false
            }
            """,
            expandedSource: """
            public class EpisodeFilter: NSObject {
                @objc public var id = 0 as Int64
                @objc public let filterDownloading = true
                @objc public var filterFinished = false

                public static let databaseTableName = "SJFilteredPlaylist"

                enum CodingKeys: String, CodingKey {
                    case id
                        case filterFinished
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        filterFinished = try container.decodeIfPresent(Bool.self, forKey: .filterFinished) ?? false
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let filterFinished = Column(CodingKeys.filterFinished)
                }
            }

            extension EpisodeFilter: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - NSObject skips non-@objc properties

    func testNSObjectSkipsNonObjcProperties() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJPodcast")
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @objc public var uuid = ""
                public var cachedUnreadCount = 0
                public var forceRefreshEpisodeFrom: String? = nil
            }
            """,
            expandedSource: """
            public class Podcast: NSObject {
                @objc public var id = 0 as Int64
                @objc public var uuid = ""
                public var cachedUnreadCount = 0
                public var forceRefreshEpisodeFrom: String? = nil

                public static let databaseTableName = "SJPodcast"

                enum CodingKeys: String, CodingKey {
                    case id
                        case uuid
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let uuid = Column(CodingKeys.uuid)
                }
            }

            extension Podcast: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - NSObject with @GRDBIgnore

    func testNSObjectWithGRDBIgnore() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            public class TestModel: NSObject {
                @objc public var id = 0 as Int64
                @objc public var name = ""

                @GRDBIgnore
                @objc public var cachedValue: String? = nil
            }
            """,
            expandedSource: """
            public class TestModel: NSObject {
                @objc public var id = 0 as Int64
                @objc public var name = ""
                @objc public var cachedValue: String? = nil

                public static let databaseTableName = "TestTable"

                enum CodingKeys: String, CodingKey {
                    case id
                        case name
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let name = Column(CodingKeys.name)
                }
            }

            extension TestModel: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Single property (no indentation issue)

    func testSingleProperty() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            public class TestModel: NSObject {
                @objc public var id = 0 as Int64
            }
            """,
            expandedSource: """
            public class TestModel: NSObject {
                @objc public var id = 0 as Int64

                public static let databaseTableName = "TestTable"

                enum CodingKeys: String, CodingKey {
                    case id
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                }
            }

            extension TestModel: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

// MARK: - Codable Class Tests

/// Tests for @GRDBRecord applied to Codable classes.
/// Pattern used by: PlaylistEpisode, UpNextChanges
final class GRDBRecordCodableClassTests: XCTestCase {

    // MARK: - Codable class with table parameter (no existing databaseTableName)

    func testCodableClassWithTableParameter() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJPlaylistEpisode")
            public class PlaylistEpisode: Codable, FetchableRecord, MutablePersistableRecord {
                public var id: Int64?
                public var episodeUuid = ""
            }
            """,
            expandedSource: """
            public class PlaylistEpisode: Codable, FetchableRecord, MutablePersistableRecord {
                public var id: Int64?
                public var episodeUuid = ""

                public static let databaseTableName = "SJPlaylistEpisode"

                public enum Columns {
                    public static let id = Column("id")
                        public static let episodeUuid = Column("episodeUuid")
                }
            }

            extension PlaylistEpisode: TableRecord {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

// MARK: - @GRDBColumn and @GRDBIgnore Marker Macro Tests

/// Tests for the marker macros that generate no code themselves.
final class GRDBMarkerMacroTests: XCTestCase {

    func testGRDBColumnMarkerMacroGeneratesNoCode() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBColumn("custom_column")
            var myProperty: String
            """,
            expandedSource: """
            var myProperty: String
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testGRDBIgnoreMarkerMacroGeneratesNoCode() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBIgnore
            var transientProperty: String?
            """,
            expandedSource: """
            var transientProperty: String?
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

// MARK: - Access Level Tests

/// Tests for proper access level propagation in generated code.
final class GRDBRecordAccessLevelTests: XCTestCase {

    // MARK: - Internal NSObject class generates internal members

    func testInternalNSObjectGeneratesInternalMembers() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            class InternalModel: NSObject {
                @objc var id = 0 as Int64
                @objc var name = ""
            }
            """,
            expandedSource: """
            class InternalModel: NSObject {
                @objc var id = 0 as Int64
                @objc var name = ""

                static let databaseTableName = "TestTable"

                enum CodingKeys: String, CodingKey {
                    case id
                        case name
                }

                required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
                }

                enum Columns {
                    static let id = Column(CodingKeys.id)
                        static let name = Column(CodingKeys.name)
                }
            }

            extension InternalModel: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Internal Codable class generates internal members

    func testInternalCodableClassGeneratesInternalMembers() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            class InternalCodable: Codable {
                var id: Int64?
                var name = ""
            }
            """,
            expandedSource: """
            class InternalCodable: Codable {
                var id: Int64?
                var name = ""

                static let databaseTableName = "TestTable"

                enum Columns {
                    static let id = Column("id")
                        static let name = Column("name")
                }
            }

            extension InternalCodable: TableRecord {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

// MARK: - Static Property Exclusion Tests

/// Tests that static properties are correctly excluded from generated code.
final class GRDBRecordStaticPropertyTests: XCTestCase {

    // MARK: - Codable class with static property excludes it from Columns

    func testCodableClassExcludesStaticProperties() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord
            public class PlaylistEpisode: Codable {
                public static let databaseTableName = "SJPlaylistEpisode"
                public var id: Int64?
                public var episodeUuid = ""
            }
            """,
            expandedSource: """
            public class PlaylistEpisode: Codable {
                public static let databaseTableName = "SJPlaylistEpisode"
                public var id: Int64?
                public var episodeUuid = ""

                public enum Columns {
                    public static let id = Column("id")
                        public static let episodeUuid = Column("episodeUuid")
                }
            }

            extension PlaylistEpisode: TableRecord {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Codable struct with multiple static properties excludes all

    func testCodableStructExcludesAllStaticProperties() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "Bookmarks")
            public struct Bookmark: Codable {
                public static let defaultTitle = "Untitled"
                public static var counter = 0
                public var id: Int64?
                public var title = ""
            }
            """,
            expandedSource: """
            public struct Bookmark: Codable {
                public static let defaultTitle = "Untitled"
                public static var counter = 0
                public var id: Int64?
                public var title = ""

                public static let databaseTableName = "Bookmarks"

                public enum Columns {
                    public static let id = Column("id")
                        public static let title = Column("title")
                }
            }

            extension Bookmark: TableRecord {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}

// MARK: - Edge Cases and Property Type Tests

/// Tests for various edge cases and property type handling.
final class GRDBRecordEdgeCaseTests: XCTestCase {

    // MARK: - Inferred types from type cast (as Int64 pattern)

    func testInferredTypesFromTypeCast() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            public class TestModel: NSObject {
                @objc public var inferredInt64 = 0 as Int64
                @objc public var inferredInt32 = 0 as Int32
                @objc public var inferredDouble = 1 as Double
            }
            """,
            expandedSource: """
            public class TestModel: NSObject {
                @objc public var inferredInt64 = 0 as Int64
                @objc public var inferredInt32 = 0 as Int32
                @objc public var inferredDouble = 1 as Double

                public static let databaseTableName = "TestTable"

                enum CodingKeys: String, CodingKey {
                    case inferredInt64
                        case inferredInt32
                        case inferredDouble
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    inferredInt64 = try container.decodeIfPresent(Int64.self, forKey: .inferredInt64) ?? 0
                        inferredInt32 = try container.decodeIfPresent(Int32.self, forKey: .inferredInt32) ?? 0
                        inferredDouble = try container.decodeIfPresent(Double.self, forKey: .inferredDouble) ?? 1
                }

                public enum Columns {
                    public static let inferredInt64 = Column(CodingKeys.inferredInt64)
                        public static let inferredInt32 = Column(CodingKeys.inferredInt32)
                        public static let inferredDouble = Column(CodingKeys.inferredDouble)
                }
            }

            extension TestModel: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Optional Date properties (Episode pattern)

    func testOptionalDateProperties() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJEpisode")
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var addedDate: Date?
                @objc public var publishedDate: Date?
                @objc public var lastPlaybackInteractionDate: Date?
            }
            """,
            expandedSource: """
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var addedDate: Date?
                @objc public var publishedDate: Date?
                @objc public var lastPlaybackInteractionDate: Date?

                public static let databaseTableName = "SJEpisode"

                enum CodingKeys: String, CodingKey {
                    case id
                        case addedDate
                        case publishedDate
                        case lastPlaybackInteractionDate
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        addedDate = try container.decodeIfPresent(Date.self, forKey: .addedDate)
                        publishedDate = try container.decodeIfPresent(Date.self, forKey: .publishedDate)
                        lastPlaybackInteractionDate = try container.decodeIfPresent(Date.self, forKey: .lastPlaybackInteractionDate)
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let addedDate = Column(CodingKeys.addedDate)
                        public static let publishedDate = Column(CodingKeys.publishedDate)
                        public static let lastPlaybackInteractionDate = Column(CodingKeys.lastPlaybackInteractionDate)
                }
            }

            extension Episode: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Negative default values (Episode.episodeNumber pattern)

    func testNegativeDefaultValues() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "SJEpisode")
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var episodeNumber = -1 as Int64
                @objc public var seasonNumber = -1 as Int64
            }
            """,
            expandedSource: """
            public class Episode: NSObject {
                @objc public var id = 0 as Int64
                @objc public var episodeNumber = -1 as Int64
                @objc public var seasonNumber = -1 as Int64

                public static let databaseTableName = "SJEpisode"

                enum CodingKeys: String, CodingKey {
                    case id
                        case episodeNumber
                        case seasonNumber
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
                        episodeNumber = try container.decodeIfPresent(Int64.self, forKey: .episodeNumber) ?? -1
                        seasonNumber = try container.decodeIfPresent(Int64.self, forKey: .seasonNumber) ?? -1
                }

                public enum Columns {
                    public static let id = Column(CodingKeys.id)
                        public static let episodeNumber = Column(CodingKeys.episodeNumber)
                        public static let seasonNumber = Column(CodingKeys.seasonNumber)
                }
            }

            extension Episode: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - String initializers with quotes

    func testStringDefaultValues() throws {
        #if canImport(GRDBMacrosPlugin)
        assertMacroExpansion(
            """
            @GRDBRecord(table: "TestTable")
            public class TestModel: NSObject {
                @objc public var emptyString = ""
                @objc public var defaultString = "default"
            }
            """,
            expandedSource: """
            public class TestModel: NSObject {
                @objc public var emptyString = ""
                @objc public var defaultString = "default"

                public static let databaseTableName = "TestTable"

                enum CodingKeys: String, CodingKey {
                    case emptyString
                        case defaultString
                }

                public required init(from decoder: Decoder) throws {
                    super.init()
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    emptyString = try container.decodeIfPresent(String.self, forKey: .emptyString) ?? ""
                        defaultString = try container.decodeIfPresent(String.self, forKey: .defaultString) ?? "default"
                }

                public enum Columns {
                    public static let emptyString = Column(CodingKeys.emptyString)
                        public static let defaultString = Column(CodingKeys.defaultString)
                }
            }

            extension TestModel: FetchableRecord, TableRecord, Decodable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
