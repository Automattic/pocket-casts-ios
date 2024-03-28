import PocketCastsUtils

public struct PodcastSettings: JSONCodable, Equatable {

    public static let defaults = PodcastSettings()

    @ModifiedDate public var customEffects: Bool = false

    @ModifiedDate public var autoStartFrom: Int32 = 0
    @ModifiedDate public var autoSkipLast: Int32 = 0

    // Playback Effects
    @ModifiedDate public var trimSilence: TrimSilence = .off
    @ModifiedDate public var boostVolume: Bool = false
    @ModifiedDate public var playbackSpeed: Double = 1

    @ModifiedDate public var notification: Bool = false

    // Auto Archive
    @ModifiedDate public var autoArchive: Bool = false
    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed = .afterPlaying
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive = .never
    @ModifiedDate public var autoArchiveEpisodeLimit: Int32 = 0

    @ModifiedDate public var addToUpNext: Bool = false
    @ModifiedDate public var addToUpNextPosition: UpNextPosition = .bottom

    @ModifiedDate public var episodesSortOrder: PodcastEpisodeSortOrder = .newestToOldest
    @ModifiedDate public var episodeGrouping: PodcastGrouping = .none
    @ModifiedDate public var showArchived: Bool = false
}
