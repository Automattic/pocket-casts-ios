import Foundation
import GRDB

public class EpisodeFilter: NSObject {
    @objc public var id = 0 as Int64
    @objc public var autoDownloadEpisodes = false
    @objc public var customIcon = 0 as Int32
    @objc public var filterAllPodcasts = false
    @objc public var filterAudioVideoType = 0 as Int32
    @objc public var filterDownloaded = false
    @objc public let filterDownloading = true // we no longer let the user change this, it's just always true
    @objc public var filterFinished = false
    @objc public var filterNotDownloaded = false
    @objc public var filterPartiallyPlayed = false
    @objc public var filterStarred = false
    @objc public var filterUnplayed = false
    @objc public var filterHours = 0 as Int32
    @objc public var playlistName = ""
    @objc public var sortPosition = 0 as Int32
    @objc public var sortType = 0 as Int32
    @objc public var uuid = ""
    @objc public var podcastUuids = ""
    @objc public var autoDownloadLimit = 0 as Int32
    @objc public var filterDuration = false
    @objc public var longerThan = 0 as Int32
    @objc public var shorterThan = 0 as Int32
    @objc public var syncStatus = 0 as Int32
    @objc public var wasDeleted = false
    @objc public var manual: Bool = false
    @objc public var showArchivedEpisodes: Bool = false
    @objc public var playlistUpdateDate: Date?

    // Internal tracking
    public var isNew: Bool = false
    public var podcastSmartRuleApplied: Bool = false
    public var episodesSmartRuleApplied: Bool = false
    public var releaseDateSmartRuleApplied: Bool = false
    public var mediaTypeSmartRuleApplied: Bool = false
    public var downloadStatusSmartRuleApplied: Bool = false

    override public init() {}

    /// A new filter pre-populated with the default "match everything" rules used when creating a playlist.
    /// Callers set the name, sort position, and any distinguishing fields (e.g. `manual`, `sortType`).
    public static func makeDefault() -> EpisodeFilter {
        let filter = EpisodeFilter()
        filter.uuid = UUID().uuidString
        filter.syncStatus = SyncStatus.notSynced.rawValue
        filter.filterAllPodcasts = true
        filter.filterUnplayed = true
        filter.filterPartiallyPlayed = true
        filter.filterFinished = true
        filter.filterDownloaded = true
        filter.filterNotDownloaded = true
        filter.filterAudioVideoType = AudioVideoFilter.all.rawValue
        return filter
    }

    public func setTitle(_ title: String?, defaultTitle: String) {
        guard let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            playlistName = defaultTitle

            return
        }

        playlistName = title
    }

    public func markingAsPlayedRemovesItem() -> Bool {
        !filterFinished
    }

    public func markingAsUnplayedRemovesItem() -> Bool {
        !filterUnplayed
    }

    public func deletingFileRemovesItem() -> Bool {
        !filterDownloaded
    }

    /// Whether an episode's download status decides if it belongs to this playlist.
    public var filtersByDownloadStatus: Bool {
        let allStatuses = filterDownloaded && filterDownloading && filterNotDownloaded
        let anyStatus = filterDownloaded || filterDownloading || filterNotDownloaded

        return !allStatuses && anyStatus
    }

    public func addPodcast(podcastUuid: String) {
        if podcastUuids.isEmpty {
            filterAllPodcasts = false
            podcastUuids = podcastUuid
        } else {
            podcastUuids.append(",\(podcastUuid)")
        }

        syncStatus = SyncStatus.notSynced.rawValue
    }

    public func removePodcast(podcastUuid: String) {
        var podcasts = podcastUuids.components(separatedBy: ",")
        podcasts.removeAll(where: { uuid -> Bool in
            podcastUuid == uuid
        })

        if podcasts.isEmpty {
            filterAllPodcasts = true
            podcastUuids = ""
        } else {
            podcastUuids = podcasts.joined(separator: ",")
        }
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherFilter = object as? EpisodeFilter else { return false }

        return otherFilter.uuid == uuid
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: id)
    }

    // MARK: - GRDB

    public static let databaseTableName = "SJFilteredPlaylist"

    enum CodingKeys: String, CodingKey {
        case id
        case autoDownloadEpisodes
        case customIcon
        case filterAllPodcasts
        case filterAudioVideoType
        case filterDownloaded
        case filterFinished
        case filterNotDownloaded
        case filterPartiallyPlayed
        case filterStarred
        case filterUnplayed
        case filterHours
        case playlistName
        case sortPosition
        case sortType
        case uuid
        case podcastUuids
        case autoDownloadLimit
        case filterDuration
        case longerThan
        case shorterThan
        case syncStatus
        case wasDeleted
        case manual
        case showArchivedEpisodes
        case playlistUpdateDate
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int64.self, forKey: .id) ?? 0
        autoDownloadEpisodes = try container.decodeIfPresent(Bool.self, forKey: .autoDownloadEpisodes) ?? false
        customIcon = try container.decodeIfPresent(Int32.self, forKey: .customIcon) ?? 0
        filterAllPodcasts = try container.decodeIfPresent(Bool.self, forKey: .filterAllPodcasts) ?? false
        filterAudioVideoType = try container.decodeIfPresent(Int32.self, forKey: .filterAudioVideoType) ?? 0
        filterDownloaded = try container.decodeIfPresent(Bool.self, forKey: .filterDownloaded) ?? false
        filterFinished = try container.decodeIfPresent(Bool.self, forKey: .filterFinished) ?? false
        filterNotDownloaded = try container.decodeIfPresent(Bool.self, forKey: .filterNotDownloaded) ?? false
        filterPartiallyPlayed = try container.decodeIfPresent(Bool.self, forKey: .filterPartiallyPlayed) ?? false
        filterStarred = try container.decodeIfPresent(Bool.self, forKey: .filterStarred) ?? false
        filterUnplayed = try container.decodeIfPresent(Bool.self, forKey: .filterUnplayed) ?? false
        filterHours = try container.decodeIfPresent(Int32.self, forKey: .filterHours) ?? 0
        playlistName = try container.decodeIfPresent(String.self, forKey: .playlistName) ?? ""
        sortPosition = try container.decodeIfPresent(Int32.self, forKey: .sortPosition) ?? 0
        sortType = try container.decodeIfPresent(Int32.self, forKey: .sortType) ?? 0
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        podcastUuids = try container.decodeIfPresent(String.self, forKey: .podcastUuids) ?? ""
        autoDownloadLimit = try container.decodeIfPresent(Int32.self, forKey: .autoDownloadLimit) ?? 0
        filterDuration = try container.decodeIfPresent(Bool.self, forKey: .filterDuration) ?? false
        longerThan = try container.decodeIfPresent(Int32.self, forKey: .longerThan) ?? 0
        shorterThan = try container.decodeIfPresent(Int32.self, forKey: .shorterThan) ?? 0
        syncStatus = try container.decodeIfPresent(Int32.self, forKey: .syncStatus) ?? 0
        wasDeleted = try container.decodeIfPresent(Bool.self, forKey: .wasDeleted) ?? false
        manual = try container.decodeIfPresent(Bool.self, forKey: .manual) ?? false
        showArchivedEpisodes = try container.decodeIfPresent(Bool.self, forKey: .showArchivedEpisodes) ?? false
        playlistUpdateDate = try container.decodeIfPresent(Date.self, forKey: .playlistUpdateDate)
    }

    public func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["autoDownloadEpisodes"] = autoDownloadEpisodes
        container["customIcon"] = customIcon
        container["filterAllPodcasts"] = filterAllPodcasts
        container["filterAudioVideoType"] = filterAudioVideoType
        container["filterDownloaded"] = filterDownloaded
        container["filterFinished"] = filterFinished
        container["filterNotDownloaded"] = filterNotDownloaded
        container["filterPartiallyPlayed"] = filterPartiallyPlayed
        container["filterStarred"] = filterStarred
        container["filterUnplayed"] = filterUnplayed
        container["filterHours"] = filterHours
        container["playlistName"] = playlistName
        container["sortPosition"] = sortPosition
        container["sortType"] = sortType
        container["uuid"] = uuid
        container["podcastUuids"] = podcastUuids
        container["autoDownloadLimit"] = autoDownloadLimit
        container["filterDuration"] = filterDuration
        container["longerThan"] = longerThan
        container["shorterThan"] = shorterThan
        container["syncStatus"] = syncStatus
        container["wasDeleted"] = wasDeleted
        container["manual"] = manual
        container["showArchivedEpisodes"] = showArchivedEpisodes
        container["playlistUpdateDate"] = playlistUpdateDate?.timeIntervalSince1970
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let autoDownloadEpisodes = Column(CodingKeys.autoDownloadEpisodes)
        public static let customIcon = Column(CodingKeys.customIcon)
        public static let filterAllPodcasts = Column(CodingKeys.filterAllPodcasts)
        public static let filterAudioVideoType = Column(CodingKeys.filterAudioVideoType)
        public static let filterDownloaded = Column(CodingKeys.filterDownloaded)
        public static let filterFinished = Column(CodingKeys.filterFinished)
        public static let filterNotDownloaded = Column(CodingKeys.filterNotDownloaded)
        public static let filterPartiallyPlayed = Column(CodingKeys.filterPartiallyPlayed)
        public static let filterStarred = Column(CodingKeys.filterStarred)
        public static let filterUnplayed = Column(CodingKeys.filterUnplayed)
        public static let filterHours = Column(CodingKeys.filterHours)
        public static let playlistName = Column(CodingKeys.playlistName)
        public static let sortPosition = Column(CodingKeys.sortPosition)
        public static let sortType = Column(CodingKeys.sortType)
        public static let uuid = Column(CodingKeys.uuid)
        public static let podcastUuids = Column(CodingKeys.podcastUuids)
        public static let autoDownloadLimit = Column(CodingKeys.autoDownloadLimit)
        public static let filterDuration = Column(CodingKeys.filterDuration)
        public static let longerThan = Column(CodingKeys.longerThan)
        public static let shorterThan = Column(CodingKeys.shorterThan)
        public static let syncStatus = Column(CodingKeys.syncStatus)
        public static let wasDeleted = Column(CodingKeys.wasDeleted)
        public static let manual = Column(CodingKeys.manual)
        public static let showArchivedEpisodes = Column(CodingKeys.showArchivedEpisodes)
        public static let playlistUpdateDate = Column(CodingKeys.playlistUpdateDate)
    }
}

extension EpisodeFilter: FetchableRecord, PersistableRecord, TableRecord, Decodable {}
