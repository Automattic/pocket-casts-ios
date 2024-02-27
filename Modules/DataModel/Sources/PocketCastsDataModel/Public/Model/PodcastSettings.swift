import PocketCastsUtils

public struct PodcastSettings: JSONCodable, Equatable {
    @ModifiedDate public var customEffects: Bool = false

    @ModifiedDate public var autoStartFrom: Int32 = 0
    @ModifiedDate public var autoSkipLast: Int32 = 0

    // Playback Effects
    @ModifiedDate public var trimSilence: TrimSilence
    @ModifiedDate public var boostVolume: Bool
    @ModifiedDate public var playbackSpeed: Double

    // Auto Archive
    @ModifiedDate public var autoArchive: Bool = false
    @ModifiedDate public var autoArchivePlayed: AutoArchiveAfterPlayed = .afterPlaying
    @ModifiedDate public var autoArchiveInactive: AutoArchiveAfterInactive = .never
    @ModifiedDate public var autoArchiveEpisodeLimit: Int32 = 0

    @ModifiedDate public var addToUpNext: Bool = false
    @ModifiedDate public var addToUpNextPosition: UpNextPosition = .bottom

    @ModifiedDate public var episodesSortOrder: PodcastEpisodeSortOrder = .shortestToLongest
    @ModifiedDate public var episodeGrouping: PodcastGrouping = .none

    public static var defaults: Self {
        return PodcastSettings(trimSilence: .off, boostVolume: false, playbackSpeed: 1)
    }
}
