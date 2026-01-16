import XCTest
import PocketCastsDataModel
import PocketCastsUtils

final class WatchSyncManagerTests: XCTestCase {
    private let debounceInterval: TimeInterval = 0.05
    private let debounceTimeout: TimeInterval = 0.5
    private let debounceQueue = DispatchQueue(label: "watch-sync-tests.debounce")

    private func makeEpisode(uuid: String) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        return episode
    }

    private func compare(phoneEpisodes: [BaseEpisode]?,
                         phoneUpNextCount: Int? = nil,
                         watchEpisodes: [BaseEpisode] = [],
                         watchEpisodeCount: Int? = nil,
                         lastServerRefresh: Date? = Date(timeIntervalSince1970: 0),
                         lastWatchDataTime: Date = Date(timeIntervalSince1970: 0)) -> UpNextComparisonResult {
        UpNextListComparator.compare(
            phoneEpisodes: phoneEpisodes,
            phoneUpNextCount: phoneUpNextCount ?? (phoneEpisodes?.count ?? 0),
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodeCount ?? watchEpisodes.count,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime
        )
    }

    // MARK: - Context Update Debouncing Tests

    func testContextUpdateDebouncing_Specification() {
        var fireCount = 0
        let expectation = expectation(description: "debounced")
        let debouncer = ContextUpdateDebouncer(interval: debounceInterval, scheduler: debounceQueue) {
            fireCount += 1
            expectation.fulfill()
        }

        debouncer.call()
        debouncer.call()
        debouncer.call()

        wait(for: [expectation], timeout: debounceTimeout)
        XCTAssertEqual(fireCount, 1)
    }

    func testTimerInvalidation_Specification() {
        let expectation = expectation(description: "no debounce fire after deinit")
        expectation.isInverted = true
        var debouncer: ContextUpdateDebouncer? = ContextUpdateDebouncer(interval: debounceInterval, scheduler: debounceQueue) {
            expectation.fulfill()
        }

        debouncer?.call()
        debouncer = nil

        wait(for: [expectation], timeout: debounceTimeout)
    }

    // MARK: - compareUpNextLists Timestamp Comparison Tests

    func testTimestampComparison_NoTimestamp_ReturnsNotEnoughInformation() {
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: nil,
            lastWatchDataTime: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(result, .notEnoughInformation)
    }

    func testTimestampComparison_PhoneNewer_ReturnsPhoneNeedsUpdate() {
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    func testTimestampComparison_WatchNewer_ReturnsWatchNeedsUpdate() {
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 100)
        let lastWatchDataTime = Date(timeIntervalSince1970: 200)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
    }

    func testTimestampComparison_EqualTimestamps_ReturnsSame() {
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastServerRefresh
        )

        XCTAssertEqual(result, .same)
    }

    // MARK: - compareUpNextLists Episode Comparison Tests

    func testEpisodeComparison_BothEmpty_ReturnsSame() {
        let result = compare(phoneEpisodes: nil, watchEpisodes: [], watchEpisodeCount: 0)

        XCTAssertEqual(result, .same)
    }

    func testEpisodeComparison_WatchHasEpisodesPhoneEmpty_ReturnsPhoneNeedsUpdate() {
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]

        let result = compare(
            phoneEpisodes: nil,
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodes.count
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    func testEpisodeComparison_TruncatedList_ReturnsNotEnoughInformation() {
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            phoneUpNextCount: 2,
            watchEpisodes: watchEpisodes
        )

        XCTAssertEqual(result, .notEnoughInformation)
    }

    func testEpisodeComparison_IdenticalEpisodes_ReturnsSame() {
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes
        )

        XCTAssertEqual(result, .same)
    }

    func testEpisodeComparison_DifferentEpisodes_FallsBackToTimestamp() {
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-3")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    // MARK: - Integration Behavior Tests

    func testIntegration_ContextUpdateFlow_WhenUncertain_ShouldNotTriggerBackgroundSync() {
        XCTAssertFalse(WatchSyncDecision.shouldPerformBackgroundRefresh(
            isPlusUser: true,
            isAppInBackground: true,
            comparisonResult: .notEnoughInformation,
            isFirstSyncInProgress: false
        ))
        XCTAssertFalse(WatchSyncDecision.shouldPerformBackgroundRefresh(
            isPlusUser: true,
            isAppInBackground: true,
            comparisonResult: .same,
            isFirstSyncInProgress: false
        ))
    }

    func testIntegration_RapidPhoneChanges_ShouldWaitForDebounce() {
        var fireCount = 0
        let expectation = expectation(description: "debounced rapid changes")
        let debouncer = ContextUpdateDebouncer(interval: debounceInterval, scheduler: debounceQueue) {
            fireCount += 1
            expectation.fulfill()
        }

        for _ in 0..<5 {
            debouncer.call()
        }

        wait(for: [expectation], timeout: debounceTimeout)
        XCTAssertEqual(fireCount, 1)
    }

    // MARK: - Regression Tests for Original Bug

    func testRegression_WatchShouldNotOverwritePhoneWithStaleData() {
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-2")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: nil,
            lastWatchDataTime: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(result, .notEnoughInformation)
    }

    func testRegression_EqualTimestampsShouldNotTriggerSync() {
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-2")]
        let timestamp = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: timestamp,
            lastWatchDataTime: timestamp
        )

        XCTAssertEqual(result, .same)
    }

    func testRegression_NoTimestampShouldNotTriggerSync() {
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-2")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: nil,
            lastWatchDataTime: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(result, .notEnoughInformation)
    }
}
