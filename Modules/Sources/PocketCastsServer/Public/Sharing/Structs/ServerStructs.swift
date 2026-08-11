import Foundation
import PocketCastsDataModel

public struct ImportOpmlResponse: Decodable {
    public var status: String? = nil
    public var message: String? = nil
    public var result: ImportOpmlResult?

    public func success() -> Bool {
        status == "ok"
    }

    public static func failedResponse() -> ImportOpmlResponse {
        var failed = ImportOpmlResponse()
        failed.status = "failed"

        return failed
    }
}

public struct ImportOpmlResult: Decodable {
    public var uuids: [String]?
    public var pollUuids: [String]?
    public var failedCount: Int

    public enum CodingKeys: String, CodingKey {
        case uuids
        case pollUuids = "poll_uuids"
        case failedCount = "failed"
    }
}

public struct ExportPodcastsResponse: Decodable {
    public var status: String? = nil
    public var message: String? = nil
    public var result: [String: String]?

    public func success() -> Bool {
        status == "ok"
    }

    public static func failedResponse() -> ExportPodcastsResponse {
        var failed = ExportPodcastsResponse()
        failed.status = "failed"

        return failed
    }
}

public struct ShareListResponse: Decodable {
    public var status: String? = nil
    public var message: String? = nil
    public var result: ShareListResult? = nil

    public func success() -> Bool {
        status == "ok"
    }

    public static func failedResponse() -> ShareListResponse {
        var failed = ShareListResponse()
        failed.status = "failed"

        return failed
    }
}

public struct ShareListResult: Decodable {
    public var time: String?
    public var podcast: SharedPodcast?
    public var episode: RefreshEpisode?

    public enum CodingKeys: String, CodingKey {
        case time, podcast
        case episode = "shared_episode"
    }
}

public struct SharedPodcast: Decodable {
    public var title: String?
    public var uuid: String?
    public var podcastDescription: String?
    public var author: String?
    public var iTunesId: Int?

    public enum CodingKeys: String, CodingKey {
        case title, uuid, author
        case podcastDescription = "description"
        case iTunesId = "collection_id"
    }
}

public struct PodcastRefreshResponse: Decodable {
    public var status: String?
    public var message: String?
    public var result: RefreshResult?

    public func success() -> Bool {
        status == "ok"
    }

    public static func failedResponse() -> PodcastRefreshResponse {
        var failed = PodcastRefreshResponse()
        failed.status = "failed"

        return failed
    }
}

public struct RefreshResult: Decodable {
    public var podcastUpdates: [String: [RefreshEpisode]]?
}

public struct RefreshEpisode: Decodable {
    public var title: String?
    public var uuid: String?
    public var url: String?
    public var episodeDescription: String?
    public var detailedDescription: String?
    public var fileType: String?
    public var sizeInBytes: Int64?
    public var duration: TimeInterval?
    public var episodeType: String?
    public var seasonNumber: Int64?
    public var episodeNumber: Int64?
    public var publishedDate: String?
    public var alternateEnclosures: [RefreshAlternateEnclosure]?

    enum CodingKeys: String, CodingKey {
        case title
        case uuid
        case url
        case episodeDescription = "description"
        case detailedDescription = "dd"
        case fileType
        case sizeInBytes
        case duration = "durationInSecs"
        case episodeType = "epType"
        case seasonNumber = "epSeason"
        case episodeNumber = "epNumber"
        case publishedDate = "publishedAt"
        case alternateEnclosures = "alternate_enclosures"
    }

    /// The HLS stream URL from the episode's alternate enclosures, if one is present.
    /// Normalises an empty `uri` to `nil` so it isn't persisted as a bogus "missing-but-present" url.
    public var hlsUrl: String? {
        let uri = alternateEnclosures?
            .first { Episode.isHLSEnclosureType($0.type) }?
            .sources?.first?.uri
        return (uri?.isEmpty ?? true) ? nil : uri
    }
}

public struct RefreshAlternateEnclosure: Decodable {
    public struct Source: Decodable {
        public var uri: String?
    }

    public var type: String?
    public var sources: [Source]?
}

public struct PodcastSearchResponse: Decodable {
    public var status: String? = nil
    public var message: String? = nil
    public var result: SearchResult? = nil

    public func success() -> Bool {
        status == "ok"
    }

    public static func failedResponse() -> PodcastSearchResponse {
        var failed = PodcastSearchResponse()
        failed.status = "failed"

        return failed
    }
}

public struct SearchResult: Decodable {
    public var podcast: PodcastInfo?
    public var searchResults: [PodcastInfo]?

    public enum CodingKeys: String, CodingKey {
        case searchResults = "search_results"

        case podcast
    }
}

public struct PodcastInfo: Codable {
    public var author: String?
    public var shortDescription: String?
    public var title: String?
    public var uuid: String?
    public var iTunesId: Int?
    public var isExplicit: Bool?

    public init() {}

    public init(from searchResult: PodcastFolderSearchResult) {
        author = searchResult.author
        title = searchResult.title
        uuid = searchResult.uuid
        isExplicit = searchResult.explicit
    }

    public enum CodingKeys: String, CodingKey {
        case shortDescription = "description"
        case iTunesId = "collection_id"
        case isExplicit = "explicit"

        case title, uuid, author
    }

    public mutating func populateFrom(discoverPodcast: DiscoverPodcast) {
        author = discoverPodcast.author
        shortDescription = discoverPodcast.shortDescription
        title = discoverPodcast.title
        uuid = discoverPodcast.uuid
        isExplicit = discoverPodcast.isExplicit
        if let iTunes = discoverPodcast.iTunesId {
            iTunesId = Int(iTunes)
        }
    }

    public func iTunesOnly() -> Bool {
        uuid == nil && iTunesId != nil
    }
}

public struct EpisodeSyncInfo {
    public var uuid: String?
    public var duration: Int?
    public var playingStatus: Int?
    public var playedUpTo: Int?
    public var isArchived: Bool?
    public var starred: Bool?
    public var deselectedChapters: String?
}

public struct PodcastSyncInfo {
    var uuid: String?
    var autoStartFrom: Int?
    var autoSkipLast: Int?
    var dateAdded: Date?
    var sortPosition: Int32?
    var folderUuid: String?
    var settings: PodcastSettings?
}

public struct FolderSyncInfo {
    var uuid: String
    var name: String
    var color: Int32
    var sortOrder: Int32
    var sortType: Int32
    var addedDate: Date
}

public struct DiscoverLayout: Decodable {
    public var layout: [DiscoverItem]?
    public var regions: [String: DiscoverRegion]?
    public var regionCodeToken: String
    public var regionNameToken: String
    public var defaultRegionCode: String

    public enum CodingKeys: String, CodingKey {
        case regionCodeToken = "region_code_token"
        case regionNameToken = "region_name_token"
        case defaultRegionCode = "default_region_code"

        case layout, regions
    }
}

public struct DiscoverRegion: Decodable {
    public var name: String
    public var code: String
    public var flag: String
}

public struct DiscoverItem: Decodable, Equatable {
    public var id: String?
    public var uuid: String?
    public var title: String?
    public var type: String?
    public var summaryStyle: String?
    public var expandedStyle: String?
    public var summaryItemCount: Int?
    public var source: String?
    public var sourceType: String?
    public var authenticated: Bool?
    public var sponsoredPodcasts: [CarouselSponsoredPodcast]?
    public var expandedTopItemLabel: String?
    public var curated: Bool?
    public var regions: [String]
    public var isSponsored: Bool?
    public var popular: [Int]?
    public var categoryID: Int?
    public var dateTime: String?
    public var sponsoredCategoryIDs: [Int]?
    // This is a local only field that is filled with the source region that was used for the item
    public var sourceRegion: String?

    public enum CodingKeys: String, CodingKey {
        case summaryStyle = "summary_style"
        case expandedStyle = "expanded_style"
        case isSponsored = "sponsored"
        case sponsoredPodcasts = "sponsored_podcasts"
        case expandedTopItemLabel = "expanded_top_item_label"
        case categoryID = "category_id"
        case dateTime = "datetime"
        case sponsoredCategoryIDs = "sponsored_ids"
        case sourceType = "source_type"
        case type, title, source, regions, curated, uuid, popular, id, authenticated
    }

    public init(
        id: String? = nil,
        uuid: String? = nil,
        title: String? = nil,
        type: String? = nil,
        summaryStyle: String? = nil,
        summaryItemCount: Int? = nil,
        expandedStyle: String? = nil,
        source: String? = nil,
        sourceType: String? = nil,
        sponsoredPodcasts: [CarouselSponsoredPodcast]? = nil,
        expandedTopItemLabel: String? = nil,
        curated: Bool? = nil,
        regions: [String],
        isSponsored: Bool? = nil,
        popular: [Int]? = nil,
        categoryID: Int? = nil,
        authenticated: Bool? = nil,
        sponsoredCategoryIDs: [Int]? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.title = title
        self.type = type
        self.summaryStyle = summaryStyle
        self.summaryItemCount = summaryItemCount
        self.expandedStyle = expandedStyle
        self.source = source
        self.sourceType = sourceType
        self.sponsoredPodcasts = sponsoredPodcasts
        self.expandedTopItemLabel = expandedTopItemLabel
        self.curated = curated
        self.regions = regions
        self.isSponsored = isSponsored
        self.popular = popular
        self.categoryID = categoryID
        self.authenticated = authenticated
        self.sponsoredCategoryIDs = sponsoredCategoryIDs
    }

    public var isAuthenticated: Bool {
        authenticated == true
    }
}

extension DiscoverItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(uuid)
    }
}

public struct CarouselSponsoredPodcast: Decodable, Equatable {
    public var position: Int?
    public var source: String?
}

public struct PodcastNetwork: Decodable {
    public var title: String?
    public var source: String?
    public var description: String?
    public var imageUrl: String?
    public var color: String?

    public enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"

        case title, source, description, color
    }
}

public struct PodcastList: Decodable {
    public var title: String?
    public var description: String?
    public var podcasts: [DiscoverPodcast]?
    public let datetime: String?
}

public struct PodcastCollection: Decodable {
    public let listId: String?
    public var title: String?
    public var subtitle: String?
    public var author: String?
    public var description: String?
    public var shortDescription: String?
    public var podcasts: [DiscoverPodcast]?
    public let episodes: [DiscoverEpisode]?
    public var podroll: [DiscoverPodcast]?
    public var collectionImage: String?
    public var collectionRectangleImage: String?
    public var colors: PodcastCollectionColors?
    public var webTitle: String?
    public var webUrl: String?
    public var collageImages: [CollageImage]?
    public let headerImage: String?
    public let featureImage: String?
    public let datetime: String?
    public enum CodingKeys: String, CodingKey {
        case webUrl = "web_url"
        case webTitle = "web_title"
        case collectionImage = "collection_image"
        case collectionRectangleImage = "collection_rectangle_image"
        case collageImages = "collage_images"
        case headerImage = "header_image"
        case listId = "list_id"
        case featureImage = "feature_image"
        case shortDescription = "short_description"
        case title, description, subtitle, colors, podcasts, author, episodes, podroll, datetime
    }
}

public struct DiscoverPodcast: Codable, Equatable, Hashable {
    public var title: String?
    public var author: String?
    public var shortDescription: String?
    public var uuid: String?
    public var website: String?
    public var iTunesId: String?
    public var isExplicit: Bool?

    public init() {}

    public enum CodingKeys: String, CodingKey {
        case shortDescription = "description"
        case iTunesId = "itunes"
        case isExplicit = "explicit"

        case title, uuid, author, website
    }

    public func iTunesOnly() -> Bool {
        uuid == nil && iTunesId != nil
    }
}

public struct DiscoverCategory: Decodable, Equatable, Sendable, Hashable {
    public var id: Int?
    public var name: String?
    public var source: String?
    public var icon: String?
    public var popularity: Int?
    public var sourceOnboarding: String?

    public init(id: Int?, name: String?) {
        self.id = id
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case source
        case icon
        case popularity
        case sourceOnboarding = "source_onboarding"
    }
}

public struct DiscoverSource: Decodable, Equatable {
    public var source: String?
    public var authenticated: Bool?
}

public struct DiscoverCategoryDetails: Decodable {
    public var title: String?
    public var description: String?
    public var podcasts: [DiscoverPodcast]?
    public var promotion: DiscoverCategoryPromotion?
}

public struct DiscoverCategoryPromotion: Decodable {
    public var promotion_uuid: String?
    public var podcast_uuid: String?
    public var title: String?
    public var description: String?
}

public struct RemoteStats {
    public var silenceRemovalTime: Int64
    public var totalListenTime: Int64
    public var autoSkipTime: Int64
    public var variableSpeedTime: Int64
    public var skipTime: Int64
    public var startedStatsAt: Int64
}

public struct PodcastCollectionColors: Codable {
    public var onLightBackground: String?
    public var onDarkBackground: String?
}

public struct CollageImage: Codable {
    public var key: String?
    public var image_url: String?
}

// MARK: Episode List

public struct DiscoverEpisode: Decodable {
    public enum CodingKeys: String, CodingKey {
        case title, duration, url, uuid, type, published, season, number

        case podcastUuid = "podcast_uuid"
        case podcastTitle = "podcast_title"
        case alternateEnclosures = "alternate_enclosures"
        case fileType = "file_type"
    }

    public let title: String?
    public let duration: Int?
    public let url: String?
    public let uuid: String?
    public let podcastUuid: String?
    public let podcastTitle: String?
    public let type: String?
    public let fileType: String?
    public let published: Date?
    public let season: Int?
    public let number: Int?
    public let alternateEnclosures: [DiscoverAlternateEnclosure]?

    public var isTrailer: Bool {
        guard let type else { return false }
        return type == "trailer"
    }

    public init(uuid: String, title: String? = nil, duration: Int? = nil, url: String? = nil, podcastUuid: String? = nil, podcastTitle: String? = nil, type: String? = nil, published: Date? = nil, season: Int? = nil, number: Int? = nil, fileType: String? = nil, alternateEnclosures: [DiscoverAlternateEnclosure]? = nil) {
        self.uuid = uuid
        self.title = title
        self.duration = duration
        self.url = url
        self.podcastUuid = podcastUuid
        self.podcastTitle = podcastTitle
        self.type = type
        self.published = published
        self.season = season
        self.number = number
        self.fileType = fileType
        self.alternateEnclosures = alternateEnclosures
    }
}

public struct DiscoverAlternateEnclosure: Decodable {
    public struct Source: Decodable {
        let uri: String
    }

    let type: String
    let sources: [Source]
}

extension DiscoverEpisode {

    static let supportedVideoTypes = Episode.hlsEnclosureTypes.union(["video/mp4"])

    public var videoURL: String? {

        if let url, let fileType, Self.supportedVideoTypes.contains(fileType.lowercased()) {
            //if the default url is already a video use it
            return url
        }

        guard let alternateEnclosures else {
            return url
        }

        let videoEnclosures = alternateEnclosures.filter { enclosure in
            Self.supportedVideoTypes.contains(enclosure.type.lowercased()) && !enclosure.sources.isEmpty
        }

        return videoEnclosures.first?.sources.first?.uri
    }
}
