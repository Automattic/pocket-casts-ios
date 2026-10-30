import Foundation
import XCTest
@testable import podcasts

final class LogUploadWaitersTests: XCTestCase {
    func testWaitReturnsTrueWhenTheUploadFinishes() async {
        let waiters = LogUploadWaiters()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            waiters.uploadFinished("log-1", succeeded: true)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertTrue(uploaded)
    }

    func testWaitReturnsFalseWhenTheUploadFails() async {
        let waiters = LogUploadWaiters()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            waiters.uploadFinished("log-1", succeeded: false)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertFalse(uploaded)
    }

    func testWaitUsesAResultThatArrivedBeforeIt() async {
        let waiters = LogUploadWaiters()
        waiters.uploadFinished("log-1", succeeded: true)

        let uploaded = await waiters.wait(for: "log-1", timeout: 5)

        XCTAssertTrue(uploaded)
    }

    func testWaitReturnsFalseAfterTheTimeout() async {
        let waiters = LogUploadWaiters()
        let start = Date()

        let uploaded = await waiters.wait(for: "log-1", timeout: 0.2)

        XCTAssertFalse(uploaded)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }

    func testAResultForAnotherLogDoesNotEndTheWait() async {
        let waiters = LogUploadWaiters()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            waiters.uploadFinished("log-2", succeeded: true)
        }

        let uploaded = await waiters.wait(for: "log-1", timeout: 0.3)

        XCTAssertFalse(uploaded)
    }
}
