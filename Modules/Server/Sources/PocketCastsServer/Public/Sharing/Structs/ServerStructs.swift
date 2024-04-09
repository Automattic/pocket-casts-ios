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
    }
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

    public init() {}

    public init(from searchResult: PodcastFolderSearchResult) {
        author = searchResult.author
        title = searchResult.title
        uuid = searchResult.uuid
    }

    public enum CodingKeys: String, CodingKey {
        case shortDescription = "description"
        case iTunesId = "collection_id"

        case title, uuid, author
    }

    public mutating func populateFrom(discoverPodcast: DiscoverPodcast) {
        author = discoverPodcast.author
        shortDescription = discoverPodcast.shortDescription
        title = discoverPodcast.title
        uuid = discoverPodcast.uuid
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
    public var source: String?
    public var sponsoredPodcasts: [CarouselSponsoredPodcast]?
    public var expandedTopItemLabel: String?
    public var curated: Bool?
    public var regions: [String]
    public var isSponsored: Bool?
    public var popular: [Int]?

    public enum CodingKeys: String, CodingKey {
        case summaryStyle = "summary_style"
        case expandedStyle = "expanded_style"
        case isSponsored = "sponsored"
        case sponsoredPodcasts = "sponsored_podcasts"
        case expandedTopItemLabel = "expanded_top_item_label"
        case type, title, source, regions, curated, uuid, popular, id
    }

    public init(id: String? = nil, title: String? = nil, source: String? = nil, regions: [String]) {
        self.id = id
        self.title = title
        self.source = source
        self.regions = regions
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
}

public struct PodcastCollection: Decodable {
    public let listId: String?
    public var title: String?
    public var subtitle: String?
    public var author: String?
    public var description: String?
    public var podcasts: [DiscoverPodcast]?
    public let episodes: [DiscoverEpisode]?
    public var collectionImage: String?
    public var colors: PodcastCollectionColors?
    public var webTitle: String?
    public var webUrl: String?
    public var collageImages: [CollageImage]?
    public let headerImage: String?
    public enum CodingKeys: String, CodingKey {
        case webUrl = "web_url"
        case webTitle = "web_title"
        case collectionImage = "collection_image"
        case collageImages = "collage_images"
        case headerImage = "header_image"
        case listId = "list_id"
        case title, description, subtitle, colors, podcasts, author, episodes
    }
}

public struct DiscoverPodcast: Codable, Equatable {
    public var title: String?
    public var author: String?
    public var shortDescription: String?
    public var uuid: String?
    public var website: String?
    public var iTunesId: String?

    public init() {}

    public enum CodingKeys: String, CodingKey {
        case shortDescription = "description"
        case iTunesId = "itunes"

        case title, uuid, author, website
    }

    public func iTunesOnly() -> Bool {
        uuid == nil && iTunesId != nil
    }
}

public struct DiscoverCategory: Decodable {
    public var id: Int?
    public var name: String?
    public var source: String?
    public var icon: String?
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
    var silenceRemovalTime: Int64
    var totalListenTime: Int64
    var autoSkipTime: Int64
    var variableSpeedTime: Int64
    var skipTime: Int64
    var startedStatsAt: Int64
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
    }

    public let title: String?
    public let duration: Int?
    public let url: String?
    public let uuid: String?
    public let podcastUuid: String?
    public let podcastTitle: String?
    public let type: String?
    public let published: Date?
    public let season: Int?
    public let number: Int?

    public var isTrailer: Bool {
        guard let type = type else { return false }
        return type == "trailer"
    }
}
