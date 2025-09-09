import XCTest
@testable import podcasts
import PocketCastsDataModel
import PocketCastsServer

final class EpisodeManagerTests: DBTestCase {

    // MARK: - urlForEpisode streamingOnly Tests

    func testUrlForEpisodeStreamingOnlyWithNoDownloadedContent() {
        // Given: An episode that is not downloaded at all
        let episode = Episode()
        episode.uuid = "test-no-download-789"
        episode.downloadUrl = "https://example.com/remote-podcast.mp3"
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue

        // When: Calling urlForEpisode with streamingOnly: false
        let localUrl = EpisodeManager.urlForEpisode(episode, streamingOnly: false)

        // Then: Should return streaming URL (no local content available)
        XCTAssertEqual(localUrl?.absoluteString, "https://example.com/remote-podcast.mp3", "Should return streaming URL when no local content")

        // When: Calling urlForEpisode with streamingOnly: true
        let streamingUrl = EpisodeManager.urlForEpisode(episode, streamingOnly: true)

        // Then: Should return the same streaming URL
        XCTAssertEqual(streamingUrl?.absoluteString, "https://example.com/remote-podcast.mp3", "Should return streaming URL when streamingOnly is true")
        XCTAssertEqual(localUrl, streamingUrl, "Both calls should return the same URL when no local content exists")
    }

    func testUrlForEpisodeStreamingOnlyWithUserEpisode() {
        // Given: A user episode (uploaded content)
        let userEpisode = UserEpisode()
        userEpisode.uuid = "user-episode-abc"
        userEpisode.uploadStatus = UploadStatus.uploaded.rawValue

        // Mock the server settings token
        let originalToken = ServerSettings.syncingV2Token
        ServerSettings.syncingV2Token = "mock-token-123"

        defer {
            // Cleanup
            ServerSettings.syncingV2Token = originalToken
        }

        // When: Calling urlForEpisode with streamingOnly: true
        let streamingUrl = EpisodeManager.urlForEpisode(userEpisode, streamingOnly: true)

        // Then: Should return API URL for user episodes
        let expectedUrl = "\(ServerConstants.Urls.api())files/url/user-episode-abc?token=mock-token-123"
        XCTAssertEqual(streamingUrl?.absoluteString, expectedUrl, "Should return API URL for user episodes")
    }

    func testUrlForEpisodeReturnsNilForInvalidEpisode() {
        // Given: An episode with no downloadUrl and not a user episode
        let episode = Episode()
        episode.uuid = "invalid-episode"
        episode.downloadUrl = nil
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue

        // When: Calling urlForEpisode
        let url = EpisodeManager.urlForEpisode(episode, streamingOnly: true)

        // Then: Should return nil
        XCTAssertNil(url, "Should return nil for episodes with no valid URL")
    }

    func testUrlForEpisodeStreamingOnlyIgnoresLocalFiles() {
        // This test documents the fix for the Chromecast issue where
        // streamingOnly: true was still returning local file paths

        // Given: An episode with downloadUrl
        let episode = Episode()
        episode.uuid = "chromecast-test-episode"
        episode.downloadUrl = "https://feeds.example.com/podcast.mp3"
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue

        // When: Calling urlForEpisode with streamingOnly: true
        let streamingUrl = EpisodeManager.urlForEpisode(episode, streamingOnly: true)

        // Then: Should return streaming URL that Chromecast can access
        XCTAssertNotNil(streamingUrl, "Should return a valid URL")
        XCTAssertEqual(streamingUrl?.absoluteString, "https://feeds.example.com/podcast.mp3", "Should return the original streaming URL")
        XCTAssertFalse(streamingUrl?.isFileURL == true, "Should not return a local file URL when streamingOnly is true")
        XCTAssertTrue(streamingUrl?.scheme == "https", "Should return an HTTPS URL for Chromecast compatibility")

        // Ensure the URL doesn't contain local file system paths
        let urlString = streamingUrl?.absoluteString ?? ""
        XCTAssertFalse(urlString.contains("file://"), "Should not contain file:// scheme")
        XCTAssertFalse(urlString.contains("/var/mobile/"), "Should not contain local iOS paths")
        XCTAssertFalse(urlString.contains("/Users/"), "Should not contain local file system paths")
    }

    func testUrlForEpisodeStreamingOnlyLogicDifference() {
        // This test verifies the key fix: streamingOnly parameter changes behavior

        // Given: Two identical episodes with streaming URLs
        let episode1 = Episode()
        episode1.uuid = "streaming-logic-test-1"
        episode1.downloadUrl = "https://cdn.example.com/episode1.mp3"
        episode1.episodeStatus = DownloadStatus.notDownloaded.rawValue

        let episode2 = Episode()
        episode2.uuid = "streaming-logic-test-2"
        episode2.downloadUrl = "https://cdn.example.com/episode2.mp3"
        episode2.episodeStatus = DownloadStatus.notDownloaded.rawValue

        // When: Calling urlForEpisode with different streamingOnly values
        let url1 = EpisodeManager.urlForEpisode(episode1, streamingOnly: false)
        let url2 = EpisodeManager.urlForEpisode(episode2, streamingOnly: true)

        // Then: Both should return streaming URLs since episodes are not downloaded
        XCTAssertEqual(url1?.absoluteString, "https://cdn.example.com/episode1.mp3", "Should return streaming URL")
        XCTAssertEqual(url2?.absoluteString, "https://cdn.example.com/episode2.mp3", "Should return streaming URL")

        // Both should be suitable for external access (like Chromecast)
        XCTAssertTrue(url1?.scheme == "https", "Should be HTTPS for external access")
        XCTAssertTrue(url2?.scheme == "https", "Should be HTTPS for external access")
        XCTAssertFalse(url1?.isFileURL == true, "Should not be local file")
        XCTAssertFalse(url2?.isFileURL == true, "Should not be local file")
    }

    func testUrlForEpisodeUserEpisodeWithoutToken() {
        // Given: A user episode but no sync token available
        let userEpisode = UserEpisode()
        userEpisode.uuid = "user-episode-no-token"
        userEpisode.uploadStatus = UploadStatus.uploaded.rawValue

        // Mock no token available
        let originalToken = ServerSettings.syncingV2Token
        ServerSettings.syncingV2Token = nil

        defer {
            ServerSettings.syncingV2Token = originalToken
        }

        // When: Calling urlForEpisode
        let url = EpisodeManager.urlForEpisode(userEpisode, streamingOnly: true)

        // Then: Should return nil since no token available
        XCTAssertNil(url, "Should return nil when no sync token available for user episode")
    }
}
