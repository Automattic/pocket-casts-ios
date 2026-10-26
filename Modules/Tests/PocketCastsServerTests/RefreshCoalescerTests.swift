import XCTest
@testable import PocketCastsServer

final class RefreshCoalescerTests: XCTestCase {

    func testBeginStartsARefreshWhenNoneIsRunning() {
        let coalescer = RefreshCoalescer()

        XCTAssertNotNil(coalescer.begin(completion: nil))
    }

    func testBeginJoinsTheRunningRefresh() {
        let coalescer = RefreshCoalescer()
        _ = coalescer.begin(completion: nil)

        XCTAssertNil(coalescer.begin(completion: nil))
    }

    func testFinishCallsTheStarterAndEveryoneWhoJoined() throws {
        let coalescer = RefreshCoalescer()
        var results = [RefreshFetchResult]()
        let id = try XCTUnwrap(coalescer.begin { results.append($0) })
        _ = coalescer.begin { results.append($0) }

        coalescer.finish(id: id, result: .newData)

        XCTAssertEqual(results, [.newData, .newData])
        XCTAssertNotNil(coalescer.begin(completion: nil), "A new refresh should start once the running one finishes")
    }

    func testFinishIgnoresARefreshThatIsNoLongerRunning() throws {
        let coalescer = RefreshCoalescer(maximumDuration: 60)
        let start = Date()
        let staleID = try XCTUnwrap(coalescer.begin(completion: nil, now: start))
        var results = [RefreshFetchResult]()
        let currentID = try XCTUnwrap(coalescer.begin(completion: { results.append($0) }, now: start.addingTimeInterval(61)))

        coalescer.finish(id: staleID, result: .noData)

        XCTAssertTrue(results.isEmpty)
        XCTAssertNil(coalescer.begin(completion: nil, now: start.addingTimeInterval(62)), "The current refresh should still be running")
        coalescer.finish(id: currentID, result: .noData)
        XCTAssertEqual(results, [.noData])
    }

    func testCancelFailsTheRunningRefresh() {
        let coalescer = RefreshCoalescer()
        var results = [RefreshFetchResult]()
        _ = coalescer.begin { results.append($0) }

        coalescer.cancel()

        XCTAssertEqual(results, [.failed])
        XCTAssertNotNil(coalescer.begin(completion: nil))
    }
}
