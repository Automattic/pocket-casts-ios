import PocketCastsUtils

public struct PodcastSettings: JSONCodable, Equatable {
    @ModifiedDate public var customEffects: Bool = false

    @ModifiedDate public var autoStartFrom: Int32 = 0
    @ModifiedDate public var autoSkipLast: Int32 = 0

    // Playback Effects
    @ModifiedDate public var trimSilence: TrimSilenceAmount
    @ModifiedDate public var boostVolume: Bool
    @ModifiedDate public var playbackSpeed: Double

    @ModifiedDate public var episodesSortOrder: PodcastEpisodeSortOrder = .shortestToLongest
    @ModifiedDate public var episodeGrouping: PodcastGrouping = .none

    public static var defaults: Self {
        return PodcastSettings(trimSilence: .off, boostVolume: false, playbackSpeed: 1)
    }
}
