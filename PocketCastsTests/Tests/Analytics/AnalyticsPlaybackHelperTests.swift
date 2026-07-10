import XCTest
import PocketCastsDataModel
import PocketCastsUtils

@testable import podcasts

class AnalyticsPlaybackHelperTests: XCTestCase {
    override func tearDown() {
        FeatureFlagOverrideStore().resetOverrides()
        super.tearDown()
    }

    private func makeHLSEpisode() -> Episode {
        let episode = Episode()
        episode.uuid = "hls-episode"
        episode.downloadUrl = "https://example.com/episode.mp3"
        episode.hlsUrl = "https://example.com/stream.m3u8"
        return episode
    }

    private func makeProgressiveEpisode() -> Episode {
        let episode = Episode()
        episode.uuid = "progressive-episode"
        episode.downloadUrl = "https://example.com/episode.mp3"
        return episode
    }

    // MARK: - hlsLifecycleProperties

    func testHlsLifecyclePropertiesReportsAvailabilityWhenFlagEnabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)

        XCTAssertEqual(AnalyticsPlaybackHelper.hlsLifecycleProperties(for: makeHLSEpisode())["hls_available"] as? Bool, true)
        XCTAssertEqual(AnalyticsPlaybackHelper.hlsLifecycleProperties(for: makeProgressiveEpisode())["hls_available"] as? Bool, false)
    }

    func testHlsLifecyclePropertiesAreEmptyWhenFlagDisabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: false)

        XCTAssertTrue(AnalyticsPlaybackHelper.hlsLifecycleProperties(for: makeHLSEpisode()).isEmpty)
    }

    func testHlsLifecyclePropertiesReportNoAvailabilityForNilEpisode() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)

        XCTAssertEqual(AnalyticsPlaybackHelper.hlsLifecycleProperties(for: nil)["hls_available"] as? Bool, false)
    }

    // MARK: - hlsProtocolProperties

    func testHlsProtocolPropertiesReportProtocolWhenFlagEnabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)

        XCTAssertEqual(AnalyticsPlaybackHelper.hlsProtocolProperties(for: makeHLSEpisode())["playback_protocol"] as? String, "hls")
        XCTAssertEqual(AnalyticsPlaybackHelper.hlsProtocolProperties(for: makeProgressiveEpisode())["playback_protocol"] as? String, "progressive")
    }

    func testHlsProtocolPropertiesAreEmptyWhenFlagDisabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: false)

        XCTAssertTrue(AnalyticsPlaybackHelper.hlsProtocolProperties(for: makeHLSEpisode()).isEmpty)
    }

    // MARK: - playbackFailed

    func testPlaybackFailedIncludesHLSContextForHLSEpisodeWhenFlagEnabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)
        let helper = AnalyticsPlaybackHelperMock()

        helper.playbackFailed(episode: makeHLSEpisode(), error: "boom", hlsErrorDetail: "internet_connection", player: nil)

        XCTAssertEqual(helper.lastEvent?.event, .playbackFailed)
        XCTAssertEqual(helper.lastEvent?.properties?["playback_protocol"] as? String, "hls")
        XCTAssertEqual(helper.lastEvent?.properties?["hls_error_detail"] as? String, "internet_connection")
    }

    func testPlaybackFailedOmitsErrorDetailForProgressiveEpisode() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)
        let helper = AnalyticsPlaybackHelperMock()

        helper.playbackFailed(episode: makeProgressiveEpisode(), error: "boom", hlsErrorDetail: "internet_connection", player: nil)

        XCTAssertEqual(helper.lastEvent?.properties?["playback_protocol"] as? String, "progressive")
        XCTAssertNil(helper.lastEvent?.properties?["hls_error_detail"], "hls_error_detail is only meaningful for HLS")
    }

    func testPlaybackFailedOmitsHLSContextWhenFlagDisabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: false)
        let helper = AnalyticsPlaybackHelperMock()

        helper.playbackFailed(episode: makeHLSEpisode(), error: "boom", hlsErrorDetail: "internet_connection", player: nil)

        XCTAssertNil(helper.lastEvent?.properties?["playback_protocol"])
        XCTAssertNil(helper.lastEvent?.properties?["hls_error_detail"])
        XCTAssertEqual(helper.lastEvent?.properties?["episode_uuid"] as? String, "hls-episode")
    }

    // MARK: - playbackSourceResolved

    func testPlaybackSourceResolvedReportsProtocolWhenFlagEnabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: true)
        let helper = AnalyticsPlaybackHelperMock()

        helper.playbackSourceResolved(for: makeHLSEpisode())

        XCTAssertEqual(helper.lastEvent?.event, .playbackSourceResolved)
        XCTAssertEqual(helper.lastEvent?.properties?["playback_protocol"] as? String, "hls")
        XCTAssertEqual(helper.lastEvent?.properties?["episode_uuid"] as? String, "hls-episode")
    }

    func testPlaybackSourceResolvedIsNotEmittedWhenFlagDisabled() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.hls, withValue: false)
        let helper = AnalyticsPlaybackHelperMock()

        helper.playbackSourceResolved(for: makeHLSEpisode())

        XCTAssertNil(helper.lastEvent, "playback_source_resolved must not fire while the HLS flag is off")
    }

    func testCurrentSourceIsRemovedAfterEventIsTriggered() {
        AnalyticsPlaybackHelper.shared.currentSource = .unknown

        AnalyticsPlaybackHelper.shared.play()

        eventually {
            XCTAssertNil(AnalyticsPlaybackHelper.shared.currentSource)
        }
    }

    func testSeekToDoesntCrashWithNanOrInfinite() {
        let helper = AnalyticsPlaybackHelperMock()

        // Forced Infinity
        helper.seek(from: .infinity, to: .infinity, duration: .infinity)
        XCTAssertNil(helper.lastEvent)

        // Forced NaN check
        helper.seek(from: .nan, to: .nan, duration: .nan)
        XCTAssertNil(helper.lastEvent)

        // Natural NaN check
        helper.seek(from: 0, to: 0, duration: 0)
        XCTAssertNil(helper.lastEvent)
    }

    func testSeekTracksValidValues() {
        let helper = AnalyticsPlaybackHelperMock()

        // 0%
        helper.seek(from: 0, to: 0, duration: 10)
        XCTAssertEqual(helper.lastEvent?.event, .playbackSeek)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_to_percent"] as? Int, 0)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_from_percent"] as? Int, 0)

        // 50% / 100%
        helper.seek(from: 10, to: 5, duration: 10)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_to_percent"] as? Int, 50)
        XCTAssertEqual(helper.lastEvent?.properties?["seek_from_percent"] as? Int, 100)
    }
}

// MARK: - AnalyticsPlaybackHelper Mock

private class AnalyticsPlaybackHelperMock: AnalyticsPlaybackHelper {
    var lastEvent: TrackEvent?

    override func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        lastEvent = .init(event: event, properties: properties)
    }

    struct TrackEvent {
        let event: AnalyticsEvent
        let properties: [String: Any]?
    }
}
