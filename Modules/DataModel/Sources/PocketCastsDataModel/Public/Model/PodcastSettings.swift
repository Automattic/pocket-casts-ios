import PocketCastsUtils

public struct PodcastSettings: JSONCodable, Equatable {
    @ModifiedDate public var customEffects: Bool = false

    // Playback Effects
    @ModifiedDate public var trimSilence: TrimSilenceAmount
    @ModifiedDate public var boostVolume: Bool
    @ModifiedDate public var playbackSpeed: Double

    public static var defaults: Self {
        return PodcastSettings(trimSilence: .off, boostVolume: false, playbackSpeed: 1)
    }
}
