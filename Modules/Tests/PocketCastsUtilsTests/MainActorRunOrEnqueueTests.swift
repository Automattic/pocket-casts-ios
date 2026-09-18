import Foundation
import PocketCastsUtils
import XCTest

final class MainActorRunOrEnqueueTests: XCTestCase {
    func testRunsSynchronouslyOnMainThread() {
        var didRun = false

        MainActor.runOrEnqueue {
            didRun = true
        }

        XCTAssertTrue(didRun)
    }

    func testEnqueuesOnMainThreadInOrderFromBackgroundThread() {
        let expectation = expectation(description: "Ran all enqueued blocks")
        expectation.expectedFulfillmentCount = 3
        var order: [Int] = []

        DispatchQueue.global().async {
            for index in 0..<3 {
                MainActor.runOrEnqueue {
                    XCTAssertTrue(Thread.isMainThread)
                    order.append(index)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(order, [0, 1, 2])
    }
}
