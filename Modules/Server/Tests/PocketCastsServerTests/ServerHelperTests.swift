import Foundation
@testable import PocketCastsServer
import XCTest

final class ServerHelperTests: XCTestCase {
    func testDecodeRefreshResponse() {
        let response = ServerHelper.decodeRefreshResponse(from: dataJSON())

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.message, nil)

        let firstPodcastUpdates = response.result?.podcastUpdates?["7622ef30-3f20-0131-77d1-723c91aeae46"]
        let secondPodcastUpdates = response.result?.podcastUpdates?["7fd817e0-2eb5-012e-0af9-00163e1b201c"]

        XCTAssertEqual(firstPodcastUpdates?.count, 2)
        XCTAssertEqual(secondPodcastUpdates?.count, 1)

        XCTAssertEqual(firstPodcastUpdates?[0].uuid, "d7dbe109-3436-4795-b608-5ef93a899d03")
        XCTAssertEqual(firstPodcastUpdates?[0].url, "https://chrt.fm/track/GD6D57")
        XCTAssertEqual(firstPodcastUpdates?[0].title, "Podcast Title")
        XCTAssertEqual(firstPodcastUpdates?[0].episodeDescription, nil)
        XCTAssertEqual(firstPodcastUpdates?[0].detailedDescription, nil)
        XCTAssertEqual(firstPodcastUpdates?[0].fileType, "audio/mp3")
        XCTAssertEqual(firstPodcastUpdates?[0].sizeInBytes, 0)
        XCTAssertEqual(firstPodcastUpdates?[0].duration, 6210)
        XCTAssertEqual(firstPodcastUpdates?[0].episodeType, "full")
        XCTAssertEqual(firstPodcastUpdates?[0].seasonNumber, 0)
        XCTAssertEqual(firstPodcastUpdates?[0].episodeNumber, 0)
        XCTAssertEqual(firstPodcastUpdates?[0].publishedDate, "2024-01-26 14:42:16")

        XCTAssertEqual(firstPodcastUpdates?[1].uuid, "99c63fd5-8ea5-438a-a3a9-60446af17794")
        XCTAssertEqual(firstPodcastUpdates?[1].url, "https://chrt.fm/track/GD6D57/url")
        XCTAssertEqual(firstPodcastUpdates?[1].title, "Podcast Title 2")
        XCTAssertEqual(firstPodcastUpdates?[1].episodeDescription, nil)
        XCTAssertEqual(firstPodcastUpdates?[1].detailedDescription, nil)
        XCTAssertEqual(firstPodcastUpdates?[1].fileType, "audio/mp3")
        XCTAssertEqual(firstPodcastUpdates?[1].sizeInBytes, 2271)
        XCTAssertEqual(firstPodcastUpdates?[1].duration, 2271)
        XCTAssertEqual(firstPodcastUpdates?[1].episodeType, "full")
        XCTAssertEqual(firstPodcastUpdates?[1].seasonNumber, 0)
        XCTAssertEqual(firstPodcastUpdates?[1].episodeNumber, 0)
        XCTAssertEqual(firstPodcastUpdates?[1].publishedDate, "2024-01-26 13:32:42")

        XCTAssertEqual(secondPodcastUpdates?[0].uuid, "161160ef-fc5b-4165-b2a3-c52963733f0c")
        XCTAssertEqual(secondPodcastUpdates?[0].url, "https://sphinx.acast.com/p/open/s/593eded1acfa040562f3480b/e/65ae84931a5c7e0017941cbc/media.mp3")
        XCTAssertEqual(secondPodcastUpdates?[0].title, "Episode 877")
        XCTAssertEqual(secondPodcastUpdates?[0].episodeDescription, nil)
        XCTAssertEqual(secondPodcastUpdates?[0].detailedDescription, nil)
        XCTAssertEqual(secondPodcastUpdates?[0].fileType, "audio/mp3")
        XCTAssertEqual(secondPodcastUpdates?[0].sizeInBytes, 89228708)
        XCTAssertEqual(secondPodcastUpdates?[0].duration, 3605)
        XCTAssertEqual(secondPodcastUpdates?[0].episodeType, "full")
        XCTAssertEqual(secondPodcastUpdates?[0].seasonNumber, 0)
        XCTAssertEqual(secondPodcastUpdates?[0].episodeNumber, 0)
        XCTAssertEqual(secondPodcastUpdates?[0].publishedDate, "2024-01-26 15:00:52")
    }
}

private extension ServerHelperTests {
    func dataJSON() -> Data {
        """
        {
            "status": "ok",
            "message": null,
            "result": {
                "podcast_updates": {
                    "7622ef30-3f20-0131-77d1-723c91aeae46": [
                        {
                            "uuid": "d7dbe109-3436-4795-b608-5ef93a899d03",
                            "url": "https://chrt.fm/track/GD6D57",
                            "website_url": null,
                            "title": "Podcast Title",
                            "description": null,
                            "dd": null,
                            "duration_in_secs": 6210,
                            "file_type": "audio/mp3",
                            "published_at": "2024-01-26 14:42:16",
                            "size_in_bytes": 0,
                            "ep_type": "full",
                            "ep_season": 0,
                            "ep_number": 0
                        },
                        {
                            "uuid": "99c63fd5-8ea5-438a-a3a9-60446af17794",
                            "url": "https://chrt.fm/track/GD6D57/url",
                            "website_url": null,
                            "title": "Podcast Title 2",
                            "description": null,
                            "dd": null,
                            "duration_in_secs": 2271,
                            "file_type": "audio/mp3",
                            "published_at": "2024-01-26 13:32:42",
                            "size_in_bytes": 2271,
                            "ep_type": "full",
                            "ep_season": 0,
                            "ep_number": 0
                        }
                    ],
                    "7fd817e0-2eb5-012e-0af9-00163e1b201c": [
                        {
                            "uuid": "161160ef-fc5b-4165-b2a3-c52963733f0c",
                            "url": "https://sphinx.acast.com/p/open/s/593eded1acfa040562f3480b/e/65ae84931a5c7e0017941cbc/media.mp3",
                            "website_url": null,
                            "title": "Episode 877",
                            "description": null,
                            "dd": null,
                            "duration_in_secs": 3605,
                            "file_type": "audio/mp3",
                            "published_at": "2024-01-26 15:00:52",
                            "size_in_bytes": 89228708,
                            "ep_type": "full",
                            "ep_season": 0,
                            "ep_number": 0
                        }
                    ]
                },
                "news": {
                    "app_version_name": "3.9",
                    "app_version_code": "51"
                }
            }
        }
        """.data(using: .utf8)!
    }
}
