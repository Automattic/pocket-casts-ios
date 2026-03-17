import XCTest
@testable import PocketCastsDataModel

final class NetworkDataUsageManagerTests: XCTestCase {
    private var dataManager: DataManager!

    override func setUp() {
        super.setUp()
        dataManager = DataManager.newTestDataManager()
    }

    override func tearDown() {
        dataManager = nil
        super.tearDown()
    }

    // MARK: - Adding Records

    func testAddRecordSucceeds() {
        let result = dataManager.networkDataUsageManager.add(
            episodeUuid: "ep-1",
            podcastUuid: "pod-1",
            bytesDownloaded: 1024,
            operationType: .download,
            connectionType: .cellular
        )
        XCTAssertTrue(result)
    }

    // MARK: - Total Data Usage

    func testTotalDataUsageSumsAllByteTypes() {
        let since = Date().addingTimeInterval(-3600)

        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 100,
            bytesStreamed: 200,
            bytesUploaded: 300,
            operationType: .download,
            connectionType: .cellular
        )

        let total = dataManager.networkDataUsageManager.totalDataUsage(since: since)
        XCTAssertEqual(total, 600)
    }

    func testTotalDataUsageFiltersByConnectionType() {
        let since = Date().addingTimeInterval(-3600)

        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 100,
            operationType: .download,
            connectionType: .cellular
        )

        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 200,
            operationType: .download,
            connectionType: .wifi
        )

        let cellularTotal = dataManager.networkDataUsageManager.totalDataUsage(since: since, connectionType: .cellular)
        XCTAssertEqual(cellularTotal, 100)

        let wifiTotal = dataManager.networkDataUsageManager.totalDataUsage(since: since, connectionType: .wifi)
        XCTAssertEqual(wifiTotal, 200)
    }

    func testTotalDataUsageExcludesOldRecords() {
        let now = Date()
        let since = now.addingTimeInterval(-3600)

        // Record from 2 hours ago (should be excluded)
        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 500,
            operationType: .download,
            connectionType: .cellular,
            timestamp: now.addingTimeInterval(-7200)
        )

        // Record from 30 minutes ago (should be included)
        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 100,
            operationType: .download,
            connectionType: .cellular,
            timestamp: now.addingTimeInterval(-1800)
        )

        let total = dataManager.networkDataUsageManager.totalDataUsage(since: since)
        XCTAssertEqual(total, 100)
    }

    // MARK: - Data Usage By Operation

    func testDataUsageByOperationGroupsCorrectly() {
        let since = Date().addingTimeInterval(-3600)

        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 100,
            operationType: .download,
            connectionType: .cellular
        )

        dataManager.networkDataUsageManager.add(
            bytesStreamed: 200,
            operationType: .stream,
            connectionType: .cellular
        )

        dataManager.networkDataUsageManager.add(
            bytesUploaded: 50,
            operationType: .upload,
            connectionType: .cellular
        )

        let byOperation = dataManager.networkDataUsageManager.dataUsageByOperation(since: since)
        XCTAssertEqual(byOperation[.download], 100)
        XCTAssertEqual(byOperation[.stream], 200)
        XCTAssertEqual(byOperation[.upload], 50)
    }

    // MARK: - Weekly Data Usage

    func testWeeklyDataUsageReturnsCorrectNumberOfWeeks() {
        let usage = dataManager.networkDataUsageManager.weeklyDataUsage(forWeeks: 4)
        XCTAssertEqual(usage.count, 4)
    }

    func testWeeklyDataUsageByTypeReturnsCorrectNumberOfWeeks() {
        let usage = dataManager.networkDataUsageManager.weeklyDataUsageByType(forWeeks: 4)
        XCTAssertEqual(usage.count, 4)
    }

    func testWeeklyDataUsageIncludesCurrentWeekData() {
        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 500,
            operationType: .download,
            connectionType: .cellular
        )

        let usage = dataManager.networkDataUsageManager.weeklyDataUsage(forWeeks: 1)
        XCTAssertEqual(usage.count, 1)
        XCTAssertEqual(usage.first?.totalBytes, 500)
    }

    // MARK: - Delete Records

    func testDeleteRecordsOlderThanDate() async {
        let now = Date()

        // Old record
        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 100,
            operationType: .download,
            connectionType: .cellular,
            timestamp: now.addingTimeInterval(-7200)
        )

        // Recent record
        dataManager.networkDataUsageManager.add(
            bytesDownloaded: 200,
            operationType: .download,
            connectionType: .cellular,
            timestamp: now
        )

        let cutoff = now.addingTimeInterval(-3600)
        let result = await dataManager.networkDataUsageManager.deleteRecords(olderThan: cutoff)
        XCTAssertTrue(result)

        let total = dataManager.networkDataUsageManager.totalDataUsage(since: now.addingTimeInterval(-86400))
        XCTAssertEqual(total, 200)
    }
}
