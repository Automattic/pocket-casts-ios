import PocketCastsUtils
import MetaCodable

@Codable
@MemberInit
public struct PodcastSettings: JSONCodable, Equatable {
    @Default(false)
    @ModifiedDate public var customEffects: Bool

    @Default(0)
    @ModifiedDate public var autoStartFrom: Int32
    @Default(0)
    @ModifiedDate public var autoSkipLast: Int32

    // Playback Effects
    @Default(TrimSilence.off)
    @ModifiedDate public var trimSilence: TrimSilence
    @Default(false)
    @ModifiedDate public var boostVolume: Bool
    @Default(1)
    @ModifiedDate public var playbackSpeed: Double

    @Default(false)
    @ModifiedDate public var notification: Bool

    // Auto Archive
    @Default(false)
    @ModifiedDate public var autoArchive: Bool
    @Default(AutoArchiveAfterPlayed.afterPlaying)
    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed
    @Default(AutoArchiveAfterInactive.never)
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive
    @Default(0)
    @ModifiedDate public var autoArchiveEpisodeLimit: Int32

    @Default(false)
    @ModifiedDate public var addToUpNext: Bool = false
    @Default(UpNextPosition.bottom)
    @ModifiedDate public var addToUpNextPosition: UpNextPosition

    @Default(PodcastEpisodeSortOrder.newestToOldest)
    @ModifiedDate public var episodesSortOrder: PodcastEpisodeSortOrder
    @Default(PodcastGrouping.none)
    @ModifiedDate public var episodeGrouping: PodcastGrouping
    @Default(false)
    @ModifiedDate public var showArchived: Bool
    @Default(false)
    @ModifiedDate public var thing: Bool
}
