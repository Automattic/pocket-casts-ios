import Foundation
import GRDB

/// Generates GRDB FetchableRecord conformance for a class.
///
/// This macro generates:
/// - `CodingKeys` enum matching all stored properties
/// - `init(from decoder: Decoder)` implementation
/// - `Columns` enum for type-safe query building
///
/// Usage:
/// ```swift
/// @GRDBRecord(table: "SJEpisode")
/// public class Episode: NSObject {
///     @objc public var id = 0 as Int64
///     @objc public var title: String?
///     @objc public var publishedDate: Date?
///     // ...
/// }
/// ```
///
/// For properties with different database column names, use @GRDBColumn:
/// ```swift
/// @GRDBRecord(table: "SJPodcast")
/// public class Podcast: NSObject {
///     @GRDBColumn("episodeKeepSetting")
///     @objc public var autoArchiveEpisodeLimit = 0 as Int32
/// }
/// ```
///
/// The macro will generate all the GRDB boilerplate automatically.
@attached(member, names: named(CodingKeys), named(init(from:)), named(Columns), named(databaseTableName))
@attached(extension, conformances: FetchableRecord, TableRecord, Decodable)
public macro GRDBRecord(table: String) = #externalMacro(module: "GRDBMacrosPlugin", type: "GRDBRecordMacro")

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

/// Generates a `Columns` enum for GRDB type-safe query building.
///
/// Use this for Codable structs/classes that already conform to FetchableRecord/PersistableRecord.
/// This macro only generates the `Columns` enum, unlike `@GRDBRecord` which generates full conformance.
///
/// Usage:
/// ```swift
/// @GRDBColumns
/// public struct Bookmark: Codable, FetchableRecord, PersistableRecord {
///     public static let databaseTableName = "Bookmark"
///     public let uuid: String
///     public var title: String
///     // ...
/// }
/// ```
///
/// For properties with different database column names, use @GRDBColumn:
/// ```swift
/// @GRDBColumns
/// public struct Bookmark: Codable, FetchableRecord, PersistableRecord {
///     @GRDBColumn("date_added")
///     public let created: Date
/// }
/// ```
@attached(member, names: named(Columns))
public macro GRDBColumns() = #externalMacro(module: "GRDBMacrosPlugin", type: "GRDBColumnsMacro")
