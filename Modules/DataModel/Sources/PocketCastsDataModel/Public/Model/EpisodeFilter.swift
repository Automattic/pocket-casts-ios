import Foundation

public class EpisodeFilter: NSObject {
    @objc public static let iconTypeCount = 8
    @objc public static let iconsPerType = 5

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

    // Internal tracking
    public var isNew: Bool = false
    public var podcastSmartRuleApplied: Bool = false
    public var episodesSmartRuleApplied: Bool = false
    public var releaseDateSmartRuleApplied: Bool = false
    public var mediaTypeSmartRuleApplied: Bool = false
    public var downloadStatusSmartRuleApplied: Bool = false

    public func setTitle(_ title: String?, defaultTitle: String) {
        guard let title = title, title.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
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

    public func addPodcast(podcastUuid: String) {
        if podcastUuids.count == 0 {
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

        if podcasts.count == 0 {
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
}
