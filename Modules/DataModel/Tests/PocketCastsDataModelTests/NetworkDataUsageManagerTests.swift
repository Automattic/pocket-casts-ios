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

        let totalCount = recordCount()
        let recentCount = recordCount(since: cutoff)
        XCTAssertEqual(totalCount, 1)
        XCTAssertEqual(recentCount, 1)
    }

    // MARK: - Helpers

    private func recordCount(since date: Date? = nil) -> Int {
        if let date {
            return dataManager.count(
                query: "SELECT COUNT(*) FROM \(NetworkDataUsageManager.tableName) WHERE timestamp >= ?",
                values: [date.timeIntervalSince1970]
            )
        }
        return dataManager.count(
            query: "SELECT COUNT(*) FROM \(NetworkDataUsageManager.tableName)",
            values: nil
        )
    }
}
