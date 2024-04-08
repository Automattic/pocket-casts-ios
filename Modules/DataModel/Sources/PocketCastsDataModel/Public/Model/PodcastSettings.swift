import PocketCastsUtils

/// Model type for synced & stored Podcast Settings
/// **NOTE:** Adding a setting requires additions to several other locations to succesfully decode and sync:
/// - `init(from: Decoder)` below in this file
/// - `SyncTask+FullSync`'s `SyncTask.processSettings(PodcastSettings, to: Podcast)`
/// - `SyncTask+LocalChanges`'s `SyncTask.apiSettings`
/// - `SyncTask+ServerChanges`'s `Podcast.processSettings(Api_PodcastSettings)`
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

extension PodcastSettings {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let defaults = PodcastSettings()

        try decode(\.$customEffects, forKey: .customEffects, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoStartFrom, forKey: .autoStartFrom, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoSkipLast, forKey: .autoSkipLast, fromContainer: container, withDefaults: defaults)
        try decode(\.$trimSilence, forKey: .trimSilence, fromContainer: container, withDefaults: defaults)
        try decode(\.$boostVolume, forKey: .boostVolume, fromContainer: container, withDefaults: defaults)
        try decode(\.$playbackSpeed, forKey: .playbackSpeed, fromContainer: container, withDefaults: defaults)
        try decode(\.$notification, forKey: .notification, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchive, forKey: .autoArchive, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchivePlayed, forKey: .autoArchivePlayed, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchiveInactive, forKey: .autoArchiveInactive, fromContainer: container, withDefaults: defaults)
        try decode(\.$autoArchiveEpisodeLimit, forKey: .autoArchiveEpisodeLimit, fromContainer: container, withDefaults: defaults)
        try decode(\.$addToUpNext, forKey: .addToUpNext, fromContainer: container, withDefaults: defaults)
        try decode(\.$addToUpNextPosition, forKey: .addToUpNextPosition, fromContainer: container, withDefaults: defaults)
        try decode(\.$episodesSortOrder, forKey: .episodesSortOrder, fromContainer: container, withDefaults: defaults)
        try decode(\.$episodeGrouping, forKey: .episodeGrouping, fromContainer: container, withDefaults: defaults)
        try decode(\.$showArchived, forKey: .showArchived, fromContainer: container, withDefaults: defaults)
    }

    private mutating func decode<Value: Codable & Equatable>(
        _ keyPath: WritableKeyPath<Self, ModifiedDate<Value>>,
        forKey key: CodingKeys,
        fromContainer container: KeyedDecodingContainer<CodingKeys>,
        withDefaults defaults: Self
    ) throws {
        self[keyPath: keyPath] = try container.decodeIfPresent(ModifiedDate<Value>.self, forKey: key) ?? defaults[keyPath: keyPath]
    }
}
