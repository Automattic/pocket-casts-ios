import Foundation

// MARK: - Domain Models

/// A YouTube playlist belonging to the authenticated user
struct YouTubeUserPlaylist: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let itemCount: Int
    let thumbnailURL: URL?
}

/// A single video inside a YouTube playlist
struct YouTubePlaylistVideo: Identifiable, Hashable, Sendable {
    let id: String           // playlistItem id (not the video id)
    let videoID: String
    let title: String
    let description: String
    let thumbnailURL: URL?
    let channelTitle: String
    let publishedAt: Date?

    /// Produces a YouTube watch URL for playback
    var watchURL: URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    }
}

/// A YouTube channel the user is subscribed to
struct YouTubeSubscription: Identifiable, Hashable, Sendable {
    let id: String              // subscription resource id
    let channelID: String       // the channel's ID
    let title: String
    let description: String
    let thumbnailURL: URL?
    let subscribedAt: Date?

    /// URL to the channel page
    var channelURL: URL {
        URL(string: "https://www.youtube.com/channel/\(channelID)")!
    }

    /// RSS feed URL for this channel (can be used with existing YouTube feed feature)
    var rssFeedURL: URL {
        URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(channelID)")!
    }

    /// Converts this subscription to a YouTubeFeed for use with existing feed views
    func toFeed() -> YouTubeFeed {
        YouTubeFeed(
            id: channelID,
            title: title,
            author: title,
            feedDescription: description,
            thumbnailURL: thumbnailURL?.absoluteString,
            feedURL: rssFeedURL.absoluteString,
            channelURL: channelURL.absoluteString
        )
    }
}

// MARK: - API Response Models

struct YouTubePlaylistListResponse: Decodable {
    let items: [YouTubePlaylistResource]
    let nextPageToken: String?

    struct YouTubePlaylistResource: Decodable {
        let id: String
        let snippet: Snippet
        let contentDetails: ContentDetails

        struct Snippet: Decodable {
            let title: String
            let description: String
            let thumbnails: Thumbnails?

            struct Thumbnails: Decodable {
                let medium: ThumbnailEntry?
                let high: ThumbnailEntry?

                struct ThumbnailEntry: Decodable {
                    let url: String
                }
            }
        }

        struct ContentDetails: Decodable {
            let itemCount: Int
        }

        func toDomain() -> YouTubeUserPlaylist {
            let thumbString = snippet.thumbnails?.medium?.url ?? snippet.thumbnails?.high?.url
            return YouTubeUserPlaylist(
                id: id,
                title: snippet.title,
                description: snippet.description,
                itemCount: contentDetails.itemCount,
                thumbnailURL: thumbString.flatMap { URL(string: $0) }
            )
        }
    }
}

struct YouTubePlaylistItemListResponse: Decodable {
    let items: [YouTubePlaylistItemResource]
    let nextPageToken: String?

    struct YouTubePlaylistItemResource: Decodable {
        let id: String
        let snippet: Snippet

        struct Snippet: Decodable {
            let title: String
            let description: String
            let publishedAt: String?
            let channelTitle: String?
            let thumbnails: Thumbnails?
            let resourceId: ResourceId

            struct Thumbnails: Decodable {
                let medium: ThumbnailEntry?
                let high: ThumbnailEntry?

                struct ThumbnailEntry: Decodable {
                    let url: String
                }
            }

            struct ResourceId: Decodable {
                let videoId: String
            }
        }

        func toDomain() -> YouTubePlaylistVideo {
            let thumbString = snippet.thumbnails?.medium?.url ?? snippet.thumbnails?.high?.url
            let date = snippet.publishedAt.flatMap {
                ISO8601DateFormatter().date(from: $0)
            }
            return YouTubePlaylistVideo(
                id: id,
                videoID: snippet.resourceId.videoId,
                title: snippet.title,
                description: snippet.description,
                thumbnailURL: thumbString.flatMap { URL(string: $0) },
                channelTitle: snippet.channelTitle ?? "",
                publishedAt: date
            )
        }
    }
}

// MARK: - Subscriptions Response

struct YouTubeSubscriptionListResponse: Decodable {
    let items: [YouTubeSubscriptionResource]
    let nextPageToken: String?

    struct YouTubeSubscriptionResource: Decodable {
        let id: String
        let snippet: Snippet

        struct Snippet: Decodable {
            let title: String
            let description: String
            let publishedAt: String?
            let thumbnails: Thumbnails?
            let resourceId: ResourceId

            struct Thumbnails: Decodable {
                let medium: ThumbnailEntry?
                let high: ThumbnailEntry?
                let `default`: ThumbnailEntry?

                struct ThumbnailEntry: Decodable {
                    let url: String
                }
            }

            struct ResourceId: Decodable {
                let channelId: String
            }
        }

        func toDomain() -> YouTubeSubscription {
            let thumbString = snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.default?.url
            let date = snippet.publishedAt.flatMap {
                ISO8601DateFormatter().date(from: $0)
            }
            return YouTubeSubscription(
                id: id,
                channelID: snippet.resourceId.channelId,
                title: snippet.title,
                description: snippet.description,
                thumbnailURL: thumbString.flatMap { URL(string: $0) },
                subscribedAt: date
            )
        }
    }
}
