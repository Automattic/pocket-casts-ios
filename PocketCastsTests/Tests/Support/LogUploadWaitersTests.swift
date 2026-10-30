import Foundation
import XCTest
@testable import podcasts

final class LogUploadWaitersTests: XCTestCase {
    func testWaitReturnsTrueWhenTheUploadFinishes() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            waiters.uploadFinished("log-1", succeeded: true)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertTrue(uploaded)
    }

    func testWaitReturnsFalseWhenTheUploadFails() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            waiters.uploadFinished("log-1", succeeded: false)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
    }

    func testWaitUsesAResultThatArrivedBeforeIt() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        waiters.uploadFinished("log-1", succeeded: true)

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertTrue(uploaded)
    }

    func testWaitReturnsFalseAfterTheTimeout() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        let start = Date()

        let uploaded = await waiters.wait(for: "log-1", timeout: 0.2)

        XCTAssertFalse(uploaded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }

    func testAResultForAnotherLogDoesNotEndTheWait() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        waiters.expect("log-2")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            waiters.uploadFinished("log-2", succeeded: true)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 0.3)

        XCTAssertFalse(uploaded)
    }

    func testWaitingForAnUnexpectedLogReturnsFalseStraightAway() async {
        let waiters = LogUploadWaiters()
        let start = Date()

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    func testAResultForAnUnexpectedLogIsDropped() async {
        let waiters = LogUploadWaiters()
        waiters.uploadFinished("log-1", succeeded: true)
        waiters.expect("log-1")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            waiters.uploadFinished("log-1", succeeded: false)
        }

        // The earlier, unexpected result isn't kept, so the wait gets the result that follows `expect`.
        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
    }

    func testAResultAfterTheTimeoutIsDropped() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        _ = await waiters.wait(for: "log-1", timeout: 0.1)

        waiters.uploadFinished("log-1", succeeded: true)
        let start = Date()
        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    func testForgetDropsTheExpectation() async {
        let waiters = LogUploadWaiters()
        waiters.expect("log-1")
        waiters.forget("log-1")
        waiters.uploadFinished("log-1", succeeded: true)

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
    }
}
