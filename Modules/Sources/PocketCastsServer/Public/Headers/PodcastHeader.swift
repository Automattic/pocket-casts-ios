import UIKit

public class PodcastHeader {
    public var headerDescription: String?
    public var title: String?
    public var author: String?
    public var uuid: String?
    public var itunesId: NSNumber?

    public init(json: [String: AnyObject]) {
        if let jsonTitle = json["title"] as? String {
            title = jsonTitle
        }
        if let jsonUuid = json["uuid"] as? String {
            uuid = jsonUuid
        }
        if let jsonDescription = json["description"] as? String {
            headerDescription = jsonDescription
        }
        if let jsonAuthor = json["author"] as? String {
            author = jsonAuthor
        }

        if let jsonItunesId = json["collection_id"] as? NSNumber {
            itunesId = jsonItunesId
        }
    }

    public init(sharedPodcast: SharedPodcast) {
        title = sharedPodcast.title
        uuid = sharedPodcast.uuid
        headerDescription = sharedPodcast.podcastDescription
        author = sharedPodcast.author
        if let iTunesId = sharedPodcast.iTunesId {
            itunesId = NSNumber(value: iTunesId)
        }
    }

    public init(uuid: String) {
        self.uuid = uuid
    }

    public func iTunesOnly() -> Bool {
        uuid == nil && itunesId != nil
    }

    public func toDiscoverPodcast() -> DiscoverPodcast {
        var discoverPodcast = DiscoverPodcast()
        discoverPodcast.author = author
        discoverPodcast.shortDescription = headerDescription
        discoverPodcast.title = title
        discoverPodcast.uuid = uuid
        if let iTunesId = itunesId?.intValue {
            discoverPodcast.iTunesId = "\(iTunesId)"
        }

        return discoverPodcast
    }
}
