import Foundation
import GRDB

/// Generates GRDB boilerplate for database record types.
///
/// The macro automatically detects the type and generates appropriate code:
///
/// **For NSObject subclasses** (e.g., Episode, Podcast):
/// - `databaseTableName` (if table parameter provided)
/// - `CodingKeys` enum matching @objc properties
/// - `init(from decoder: Decoder)` implementation
/// - `Columns` enum for type-safe query building
/// - Adds conformances: `FetchableRecord`, `TableRecord`, `Decodable`
///
/// **For structs/classes** (e.g., Bookmark, PlaylistEpisode):
/// - `databaseTableName` (if table parameter provided)
/// - `CodingKeys` enum with custom column name mappings via @GRDBColumn
/// - `Columns` enum for type-safe query building
/// - Adds conformances: `Codable`, `FetchableRecord`, `PersistableRecord`
///
/// Usage for NSObject classes:
/// ```swift
/// @GRDBRecord(table: "SJEpisode")
/// public class Episode: NSObject {
///     @objc public var id = 0 as Int64
///     @objc public var title: String?
/// }
/// ```
///
/// Usage for structs (all GRDB boilerplate generated automatically):
/// ```swift
/// @GRDBRecord(table: "Bookmark")
/// public struct Bookmark: Hashable {
///     public let uuid: String
///     public var title: String
///
///     @GRDBColumn("date_added")
///     public let created: Date
///
///     @GRDBIgnore
///     public var episode: BaseEpisode? = nil
/// }
/// ```
///
/// For properties with different database column names, use @GRDBColumn:
/// ```swift
/// @GRDBColumn("episodeKeepSetting")
/// @objc public var autoArchiveEpisodeLimit = 0 as Int32
/// ```
@attached(member, names: named(CodingKeys), named(init(from:)), named(Columns), named(databaseTableName))
@attached(extension, conformances: Codable, FetchableRecord, PersistableRecord, TableRecord, Decodable)
public macro GRDBRecord(table: String? = nil) = #externalMacro(module: "GRDBMacrosPlugin", type: "GRDBRecordMacro")

/// Specifies a custom database column name for a property.
///
/// Use this when the Swift property name differs from the database column name.
///
/// Usage:
/// ```swift
/// @GRDBColumn("episodeKeepSetting")
/// @objc public var autoArchiveEpisodeLimit = 0 as Int32
/// ```
@attached(peer)
public macro GRDBColumn(_ columnName: String) = #externalMacro(module: "GRDBMacrosPlugin", type: "GRDBColumnMacro")

/// Marks a property to be ignored by @GRDBRecord.
///
/// Use this for transient properties that should not be included in
/// CodingKeys, Columns, or database operations.
///
/// Usage:
/// ```swift
/// @GRDBIgnore
/// public var episode: BaseEpisode? = nil
/// ```
@attached(peer)
public macro GRDBIgnore() = #externalMacro(module: "GRDBMacrosPlugin", type: "GRDBIgnoreMacro")
