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
                         lastWatchDataTime: Date = Date(timeIntervalSince1970: 0),
                         lastLocalQueueChange: Date? = nil,
                         useConservativeComparison: Bool = true) -> UpNextComparisonResult {
        UpNextListComparator.compare(
            phoneEpisodes: phoneEpisodes,
            phoneUpNextCount: phoneUpNextCount ?? (phoneEpisodes?.count ?? 0),
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodeCount ?? watchEpisodes.count,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange,
            useConservativeComparison: useConservativeComparison
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

    func testTimestampComparison_NoLocalChanges_ReturnsWatchNeedsUpdate() {
        // When there are no local changes, phone is always source of truth
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: nil
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
    }

    func testTimestampComparison_LocalChangeBeforePhoneData_ReturnsWatchNeedsUpdate() {
        // Local change happened BEFORE receiving phone data, so phone is still source of truth
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 150)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 100) // Before phone data

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
    }

    func testTimestampComparison_LocalChangeAfterPhoneData_ReturnsPhoneNeedsUpdate() {
        // Local change happened AFTER receiving phone data, so Watch changes should sync
        let phoneEpisodes = [makeEpisode(uuid: "phone-1")]
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 150) // After phone data

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    // MARK: - compareUpNextLists Episode Comparison Tests

    func testEpisodeComparison_BothEmpty_ReturnsSame() {
        let result = compare(phoneEpisodes: nil, watchEpisodes: [], watchEpisodeCount: 0)

        XCTAssertEqual(result, .same)
    }

    func testEpisodeComparison_WatchHasEpisodesPhoneNil_ReturnsNotEnoughInformation() {
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]

        let result = compare(
            phoneEpisodes: nil,
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodes.count
        )

        XCTAssertEqual(result, .notEnoughInformation)
    }

    func testEpisodeComparison_WatchHasEpisodesPhoneExplicitlyEmpty_ReturnsWatchNeedsUpdate() {
        let watchEpisodes = [makeEpisode(uuid: "watch-1")]

        let result = compare(
            phoneEpisodes: [],
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodes.count
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
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

    func testEpisodeComparison_DifferentEpisodes_NoLocalChanges_ReturnsWatchNeedsUpdate() {
        // When episodes differ but no local changes, phone is source of truth
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-3")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: nil
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
    }

    func testEpisodeComparison_DifferentEpisodes_WithLocalChanges_ReturnsPhoneNeedsUpdate() {
        // When episodes differ AND Watch made local changes after phone data, sync Watch to server
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-3")]
        let lastServerRefresh = Date(timeIntervalSince1970: 200)
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 150) // After phone data

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
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

    func testIntegration_PhoneClearedQueue_ShouldPullFromPhone() {
        let watchEpisodes = [makeEpisode(uuid: "watch-1"), makeEpisode(uuid: "watch-2")]

        let comparisonResult = compare(
            phoneEpisodes: [],
            phoneUpNextCount: 0,
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: watchEpisodes.count,
            lastServerRefresh: Date(timeIntervalSince1970: 100),
            lastWatchDataTime: Date(timeIntervalSince1970: 50)
        )

        XCTAssertEqual(comparisonResult, .watchNeedsUpdate)
        XCTAssertTrue(WatchSyncDecision.shouldPerformBackgroundRefresh(
            isPlusUser: true,
            isAppInBackground: true,
            comparisonResult: comparisonResult,
            isFirstSyncInProgress: false
        ))
    }

    // MARK: - Regression Tests for Original Bug

    func testRegression_WatchShouldNotOverwritePhoneWithStaleData() {
        // When Watch has different data but no local changes, phone is source of truth
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-2")]

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: nil,
            lastWatchDataTime: Date(timeIntervalSince1970: 100),
            lastLocalQueueChange: nil
        )

        // With no server refresh timestamp in conservative mode, we don't have enough info
        XCTAssertEqual(result, .notEnoughInformation)
    }

    func testRegression_WatchWithStaleDataNoLocalChanges_ShouldUpdateFromPhone() {
        // Watch has stale data (old episodes), no local changes → pull from phone
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-2"), makeEpisode(uuid: "ep-3"), makeEpisode(uuid: "ep-4")]
        let lastServerRefresh = Date(timeIntervalSince1970: 100)
        let lastWatchDataTime = Date(timeIntervalSince1970: 50)

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: nil
        )

        XCTAssertEqual(result, .watchNeedsUpdate)
    }

    func testRegression_WatchLocalChanges_ShouldSyncToServer() {
        // Watch user made local changes → those should sync to server
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let lastServerRefresh = Date(timeIntervalSince1970: 100)
        let lastWatchDataTime = Date(timeIntervalSince1970: 50)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 75) // After phone data

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: lastServerRefresh,
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
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

    // MARK: - Watch Queue Management Tests

    func testWatchQueueManagement_AddEpisodeOnWatch_ShouldSync() {
        // User adds an episode on Watch after receiving phone data
        let phoneEpisodes = [makeEpisode(uuid: "ep-1")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 150) // User added ep-2

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: Date(timeIntervalSince1970: 200),
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    func testWatchQueueManagement_RemoveEpisodeOnWatch_ShouldSync() {
        // User removes an episode on Watch after receiving phone data
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes = [makeEpisode(uuid: "ep-1")]
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 150) // User removed ep-2

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            lastServerRefresh: Date(timeIntervalSince1970: 200),
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }

    func testWatchQueueManagement_ClearQueueOnWatch_ShouldSync() {
        // User clears queue on Watch after receiving phone data
        let phoneEpisodes = [makeEpisode(uuid: "ep-1"), makeEpisode(uuid: "ep-2")]
        let watchEpisodes: [BaseEpisode] = []
        let lastWatchDataTime = Date(timeIntervalSince1970: 100)
        let lastLocalQueueChange = Date(timeIntervalSince1970: 150) // User cleared queue

        let result = compare(
            phoneEpisodes: phoneEpisodes,
            watchEpisodes: watchEpisodes,
            watchEpisodeCount: 0,
            lastServerRefresh: Date(timeIntervalSince1970: 200),
            lastWatchDataTime: lastWatchDataTime,
            lastLocalQueueChange: lastLocalQueueChange
        )

        XCTAssertEqual(result, .phoneNeedsUpdate)
    }
}
