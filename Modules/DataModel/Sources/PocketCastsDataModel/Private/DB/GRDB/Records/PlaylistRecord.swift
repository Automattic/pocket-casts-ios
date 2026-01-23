import Foundation
import GRDB

/// GRDB Record type representing the SJFilteredPlaylist table.
/// Used for strongly-typed query building with GRDB's QueryInterface.
struct PlaylistRecord: Codable, Identifiable {
    var id: Int64?
    var autoDownloadEpisodes: Bool
    var customIcon: Int32
    var filterAllPodcasts: Bool
    var filterAudioVideoType: Int32
    var filterDownloaded: Bool
    var filterDownloading: Bool
    var filterFinished: Bool
    var filterNotDownloaded: Bool
    var filterPartiallyPlayed: Bool
    var filterStarred: Bool
    var filterUnplayed: Bool
    var manual: Bool
    var playlistName: String
    var podcastUuids: String?
    var sortPosition: Int32
    var sortType: Int32
    var uuid: String
    var syncStatus: Int32
    var wasDeleted: Bool
    var filterHours: Int32
    var autoDownloadLimit: Int32
    var filterDuration: Bool
    var longerThan: Int32
    var shorterThan: Int32
    var showArchivedEpisodes: Bool
    var playlistUpdateDate: Double?

    /// Initializes a default PlaylistRecord with reasonable defaults
    init() {
        self.id = nil
        self.autoDownloadEpisodes = false
        self.customIcon = 0
        self.filterAllPodcasts = false
        self.filterAudioVideoType = 0
        self.filterDownloaded = false
        self.filterDownloading = false
        self.filterFinished = false
        self.filterNotDownloaded = false
        self.filterPartiallyPlayed = false
        self.filterStarred = false
        self.filterUnplayed = false
        self.manual = false
        self.playlistName = ""
        self.podcastUuids = nil
        self.sortPosition = 0
        self.sortType = 0
        self.uuid = ""
        self.syncStatus = 0
        self.wasDeleted = false
        self.filterHours = 0
        self.autoDownloadLimit = 0
        self.filterDuration = false
        self.longerThan = 0
        self.shorterThan = 0
        self.showArchivedEpisodes = false
        self.playlistUpdateDate = nil
    }
}

// MARK: - FetchableRecord & PersistableRecord

extension PlaylistRecord: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "SJFilteredPlaylist"

    /// Updates the record's id after it has been inserted in the database.
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Column Definitions

extension PlaylistRecord {
    /// Column definitions for type-safe query building
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let autoDownloadEpisodes = Column(CodingKeys.autoDownloadEpisodes)
        static let customIcon = Column(CodingKeys.customIcon)
        static let filterAllPodcasts = Column(CodingKeys.filterAllPodcasts)
        static let filterAudioVideoType = Column(CodingKeys.filterAudioVideoType)
        static let filterDownloaded = Column(CodingKeys.filterDownloaded)
        static let filterDownloading = Column(CodingKeys.filterDownloading)
        static let filterFinished = Column(CodingKeys.filterFinished)
        static let filterNotDownloaded = Column(CodingKeys.filterNotDownloaded)
        static let filterPartiallyPlayed = Column(CodingKeys.filterPartiallyPlayed)
        static let filterStarred = Column(CodingKeys.filterStarred)
        static let filterUnplayed = Column(CodingKeys.filterUnplayed)
        static let manual = Column(CodingKeys.manual)
        static let playlistName = Column(CodingKeys.playlistName)
        static let podcastUuids = Column(CodingKeys.podcastUuids)
        static let sortPosition = Column(CodingKeys.sortPosition)
        static let sortType = Column(CodingKeys.sortType)
        static let uuid = Column(CodingKeys.uuid)
        static let syncStatus = Column(CodingKeys.syncStatus)
        static let wasDeleted = Column(CodingKeys.wasDeleted)
        static let filterHours = Column(CodingKeys.filterHours)
        static let autoDownloadLimit = Column(CodingKeys.autoDownloadLimit)
        static let filterDuration = Column(CodingKeys.filterDuration)
        static let longerThan = Column(CodingKeys.longerThan)
        static let shorterThan = Column(CodingKeys.shorterThan)
        static let showArchivedEpisodes = Column(CodingKeys.showArchivedEpisodes)
        static let playlistUpdateDate = Column(CodingKeys.playlistUpdateDate)
    }
}

// MARK: - Associations

extension PlaylistRecord {
    /// Association to playlist episodes
    static let playlistEpisodes = hasMany(PlaylistEpisodeRecord.self, using: PlaylistEpisodeRecord.playlistForeignKey)
}
