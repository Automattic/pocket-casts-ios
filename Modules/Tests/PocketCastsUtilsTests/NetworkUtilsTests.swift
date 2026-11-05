import Foundation
import PocketCastsUtils
import XCTest

final class NetworkUtilsTests: XCTestCase {
    func testWhenConnectedCallsHandlerOnceOnMainQueue() {
        let handlerCalled = expectation(description: "Handler called")
        DispatchQueue.global(qos: .default).async {
            NetworkUtils.shared.whenConnected(timeout: 0.1) {
                XCTAssertTrue(Thread.isMainThread)
                handlerCalled.fulfill()
            }
        }
        wait(for: [handlerCalled], timeout: 5)

        let timeoutPassed = expectation(description: "Timeout passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            timeoutPassed.fulfill()
        }
        wait(for: [timeoutPassed], timeout: 5)
    }
}
