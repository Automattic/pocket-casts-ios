import UIKit

public class EpisodeHeader {
    public var uuid: String?
    public var episodeDescription: String?
    public var publishedDate: Date?
    public var title: String?
    public var sizeInBytes: Int64?
    public var fileType: String?
    public var duration: Double?
    public var downloadUrl: String?

    public init(refreshEpisode: RefreshEpisode) {
        uuid = refreshEpisode.uuid
        episodeDescription = refreshEpisode.episodeDescription ?? refreshEpisode.detailedDescription
        title = refreshEpisode.title
        sizeInBytes = refreshEpisode.sizeInBytes
        fileType = refreshEpisode.fileType
        duration = refreshEpisode.duration
        downloadUrl = refreshEpisode.url

        publishedDate = JsonUtil.convert(jsonDate: refreshEpisode.publishedDate)
    }

    public func populateFrom(json: [String: AnyObject]) {
        if let jsonTitle = json["title"] as? String {
            title = jsonTitle
        }
        if let jsonUuid = json["uuid"] as? String {
            uuid = jsonUuid
        }
        if let url = json["url"] as? String {
            downloadUrl = url
        }
        if let jsonSize = json["size_in_bytes"] as? Int64 {
            sizeInBytes = jsonSize
        }
        if let jsonDuration = json["duration_in_secs"] as? Double {
            duration = jsonDuration
        }

        // take the longest of the two available descriptions
        if let desc1 = json["description"] as? String, let desc2 = json["dd"] as? String {
            episodeDescription = desc1.count > desc2.count ? desc1 : desc2
        } else if let jsonDescription = json["description"] as? String {
            episodeDescription = jsonDescription
        } else if let jsonDescription = json["dd"] as? String {
            episodeDescription = jsonDescription
        }

        if let jsonFileType = json["file_type"] as? String {
            fileType = jsonFileType
        }

        publishedDate = JsonUtil.convert(jsonDate: json["published_at"])
    }
}
