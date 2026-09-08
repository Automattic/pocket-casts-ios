#if DEBUG

import Combine
import Foundation
import PocketCastsServer

/// Canned Discover responses, so a section preview renders without touching the network.
///
/// The server models are `Decodable`-only, so the fixtures are built the way the real ones are:
/// decoded from JSON shaped like the payloads `DiscoverServerHandler` fetches. Feed them to a
/// section through ``PreviewDiscoverServerHandler``.
enum DiscoverPreviewData {

    // MARK: - Podcasts

    /// Podcasts whose artwork exists on the live CDN, so the first few covers in a preview are
    /// real ones. Everything past these falls back to the grid placeholder.
    private static let artworkUUIDs = [
        "82e37e80-755d-0138-eddc-0acc26574db2",
        "9478cc80-7c42-0138-edfe-0acc26574db2",
        "37082d70-e945-0137-b6eb-0acc26574db2",
        "62200ab0-b7ec-0139-f606-0acc26574db2"
    ]

    private static let showTitles = [
        "Deep Sleep Sounds",
        "Get Sleepy: Sleep Meditation",
        "Sleep Whispers",
        "Nothing Much Happens",
        "The Rest Is History",
        "Search Engine",
        "Hard Fork",
        "Ologies",
        "Shop Talk",
        "The Bugle",
        "Cautionary Tales",
        "Dear Hank & John",
        "Song Exploder",
        "Reply All Forever",
        "Twenty Thousand Hertz",
        "The Anthropocene Reviewed",
        "Radio Ambulante",
        "Field Recordings",
        "A Very Long Walk",
        "Late Night Radio Hour"
    ]

    private static let authors = [
        "Slumber Studios", "Wavelength", "PJ & Alex", "Tiny Desk Media", "Goalhanger",
        "Jigsaw Audio", "Northbound", "Alie Ward", "Studio Ochre", "Bugle Media"
    ]

    private static let blurbs = [
        "Drift off to gentle soundscapes recorded in remote places.",
        "A bedtime story for grown ups, told slowly and kindly.",
        "Whispered tales and trivia to help you fall asleep.",
        "Long form conversations about the things nobody explains.",
        "History, told badly, by people who love it far too much."
    ]

    /// `count` podcasts with stable identity, so lists don't churn between preview renders.
    static func podcasts(_ count: Int) -> [DiscoverPodcast] {
        (0 ..< count).map(podcast(at:))
    }

    static func podcast(at index: Int) -> DiscoverPodcast {
        var podcast = DiscoverPodcast()
        podcast.uuid = index < artworkUUIDs.count ? artworkUUIDs[index] : "preview-podcast-\(index)"
        podcast.title = showTitles[index % showTitles.count]
        podcast.author = authors[index % authors.count]
        podcast.shortDescription = blurbs[index % blurbs.count]
        podcast.isExplicit = index % 5 == 3
        return podcast
    }

    // MARK: - Lists, collections and categories

    static func podcastList(title: String, description: String? = nil, podcasts: [DiscoverPodcast]) -> PodcastList {
        decode(PodcastList.self, from: [
            "title": title,
            "description": description,
            "podcasts": encoded(podcasts),
            "datetime": datetime
        ])
    }

    static func podcastCollection(
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        shortDescription: String? = nil,
        podcasts: [DiscoverPodcast],
        collectionImage: String? = nil,
        featureImage: String? = nil
    ) -> PodcastCollection {
        decode(PodcastCollection.self, from: [
            "list_id": "preview-collection",
            "title": title,
            "subtitle": subtitle,
            "description": description,
            "short_description": shortDescription,
            "podcasts": encoded(podcasts),
            "collection_image": collectionImage,
            "feature_image": featureImage,
            "datetime": datetime
        ])
    }

    /// The single-episode section reads the first episode of a collection.
    static func episodeCollection(
        title: String,
        episodeTitle: String,
        podcastTitle: String,
        podcastUUID: String = artworkUUIDs[0],
        duration: Int = 2_412,
        isTrailer: Bool = false,
        colors: (light: String, dark: String)? = nil
    ) -> PodcastCollection {
        decode(PodcastCollection.self, from: [
            "list_id": "preview-episode-collection",
            "title": title,
            "colors": colors.map { ["onLightBackground": $0.light, "onDarkBackground": $0.dark] },
            "episodes": [[
                "uuid": "preview-episode",
                "title": episodeTitle,
                "podcast_uuid": podcastUUID,
                "podcast_title": podcastTitle,
                "duration": duration,
                "type": isTrailer ? "trailer" : "full",
                "published": "2026-08-19T09:00:00Z",
                "season": 4,
                "number": 12
            ]],
            "datetime": datetime
        ])
    }

    static let categoryNames = [
        "Arts", "Business", "Comedy", "Education", "Fiction", "Health & Fitness",
        "History", "News", "Science", "Society & Culture", "Sports", "Technology"
    ]

    static func categories(_ count: Int = categoryNames.count) -> [DiscoverCategory] {
        (0 ..< min(count, categoryNames.count)).map { index in
            var category = DiscoverCategory(id: index + 1, name: categoryNames[index])
            category.source = "https://lists.pocketcasts.com/preview-category-\(index + 1).json"
            category.icon = "https://static.pocketcasts.com/discover/images/category-\(index + 1).png"
            category.popularity = count - index
            return category
        }
    }

    static func categoryDetails(
        title: String,
        podcasts: [DiscoverPodcast],
        promotion: (title: String, description: String)? = nil
    ) -> DiscoverCategoryDetails {
        decode(DiscoverCategoryDetails.self, from: [
            "title": title,
            "description": "The best of \(title), updated every week.",
            "podcasts": encoded(podcasts),
            "promotion": promotion.map {
                [
                    "promotion_uuid": "preview-promotion",
                    "podcast_uuid": artworkUUIDs[1],
                    "title": $0.title,
                    "description": $0.description
                ]
            }
        ])
    }

    /// Networks the live `lists_list` carries, so previews show the logos and blurbs of real ones.
    private static let networks: [(uuid: String, title: String, description: String, imageType: String, itemCount: Int)] = [
        ("88094252-ec9a-4c96-9120-95413664d9de", "The New York Times", "The New York Times collection of podcasts", "png", 12),
        ("979866dc-fcb6-400d-8586-9e5003ef33b8", "Relay", "The Relay collection of podcasts.", "png", 19),
        ("71c61818-1a5b-4bc5-9bb4-605318342b0c", "Maximum Fun", "Artist-owned comedy & culture shows", "jpg", 41),
        ("a3d4dc76-3d2d-4698-bf2d-b01897512ed6", "Crime House", "Uncovering the truth", "jpg", 8),
        ("af1ded0b-bea1-4abc-ac0f-3881cb41b57d", "Podmasters", "Exciting character-driven podcasts", "jpg", 7),
        ("e8d51650-df8a-4a5e-a157-1f7b636fac8d", "Higher Ground", "Widely acclaimed stories that move culture forward", "jpg", 9),
        ("6dd34339-bc03-4539-abae-4e3ff5b9fe59", "The Sonar Podcast Network", "The funny & the fascinating.", "jpg", 9),
        ("4562eca8-14fd-4661-97bb-362a728d7e9f", "Slumber Studios", "The perfect podcasts for bedtime.", "jpg", 5),
        ("77734d74-bdce-4934-87b0-40c8e33e3962", "Pushkin Industries", "Good, Smart, Fun.", "jpg", 10),
        ("084e3d50-159e-464a-9642-24e0be93af3d", "Multitude", "We contain worlds", "jpg", 8),
        ("b9028838-a60e-474a-9fe3-69a22c321286", "TAPEDECK", "Independent podcasts with familiar voices.", "jpg", 10),
        ("da7e9206-3777-4715-ae60-29de3418bb1e", "Broads and Books Productions", "Broads and Books Productions creates podcasts that make you laugh, think, rage, and all of the above.", "jpg", 4),
        ("45453984-cba5-4613-9d7a-bb73dd7a9f6b", "RNZ", "The best podcasts from New Zealand", "jpg", 25),
        ("872898e6-33d5-48a9-b824-15104c64f5bc", "Atypical Artists", "Stories for your ears and hearts.", "jpg", 12)
    ]

    /// The `lists_list` payload: a collection whose entries are podcast lists, one per network.
    ///
    /// Tops out at the number of networks the fixture holds, so every entry stays a distinct one.
    static func networkCollection(title: String, count: Int = 6) -> PodcastCollection {
        decode(PodcastCollection.self, from: [
            "list_id": "preview-networks",
            "title": title,
            "lists": networks.prefix(count).map { network in
                [
                    "uuid": network.uuid,
                    "title": network.title,
                    "type": NetworkListSummary.supportedType,
                    "summary_style": "collection",
                    "expanded_style": "network_grid",
                    "source": "https://lists.pocketcasts.com/\(network.uuid).json",
                    "collection_image": "https://static.pocketcasts.com/share/images/\(network.uuid)-author.\(network.imageType)",
                    "item_count": network.itemCount,
                    "description": network.description
                ]
            },
            "datetime": datetime
        ])
    }

    static func sponsoredPodcast(position: Int, source: String) -> CarouselSponsoredPodcast {
        decode(CarouselSponsoredPodcast.self, from: ["position": position, "source": source])
    }

    // MARK: - Discover items

    /// A layout entry that `cellType()` resolves to `cellType`.
    static func item(
        _ cellType: DiscoverCellType,
        title: String,
        source: String = "https://lists.pocketcasts.com/preview.json",
        expandedStyle: String? = "plain_list",
        summaryItemCount: Int? = nil,
        sponsoredPodcasts: [CarouselSponsoredPodcast]? = nil,
        isSponsored: Bool? = nil,
        popular: [Int]? = nil
    ) -> DiscoverItem {
        let styles = styles(for: cellType)
        return DiscoverItem(
            id: "preview-\(title)",
            uuid: "preview-list",
            title: title,
            type: styles.type,
            summaryStyle: styles.summaryStyle,
            summaryItemCount: summaryItemCount,
            expandedStyle: expandedStyle,
            source: source,
            sponsoredPodcasts: sponsoredPodcasts,
            regions: ["us"],
            isSponsored: isSponsored,
            popular: popular,
            categoryID: 1,
            authenticated: false
        )
    }

    private static func styles(for cellType: DiscoverCellType) -> (type: String, summaryStyle: String) {
        switch cellType {
        case .categoriesSelector: ("categories", "pills")
        case .featuredSummary: ("podcast_list", "carousel")
        case .smallPagedListSummary: ("podcast_list", "small_list")
        case .largeListSummary: ("podcast_list", "large_list")
        case .singlePodcast: ("podcast_list", "single_podcast")
        case .collectionSummary: ("podcast_list", "collection")
        case .categorySummary: ("categories", "category")
        case .singleEpisode: ("episode_list", "single_episode")
        case .categoryPodcasts: ("category_podcast_list", "category_podcast_list")
        case .largeListWithPodcast: ("podcast_list", "large_list_with_podcast")
        case .networksList: ("lists_list", "large_list")
        }
    }

    /// A podcast's cover on the live CDN, standing in for artwork a preview has none of.
    private static func artworkURL(at index: Int) -> String {
        "https://static.pocketcasts.com/discover/images/420/\(artworkUUIDs[index % artworkUUIDs.count]).jpg"
    }

    // MARK: - JSON plumbing

    /// Matches the generation timestamp the server stamps on every list.
    private static let datetime = "2026-08-19T09:00:00Z"

    private static func encoded(_ podcasts: [DiscoverPodcast]) -> Any {
        let data = try! JSONEncoder().encode(podcasts)
        return try! JSONSerialization.jsonObject(with: data)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from json: [String: Any?]) -> T {
        let data = try! JSONSerialization.data(withJSONObject: json.compactMapValues { $0 })
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(type, from: data)
    }
}

#endif
