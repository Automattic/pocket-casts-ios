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
        }
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
