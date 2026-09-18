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
}

extension EpisodeFilter: PersistableRecord {}
