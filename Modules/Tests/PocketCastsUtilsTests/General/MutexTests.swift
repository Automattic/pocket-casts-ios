import XCTest

@testable import PocketCastsUtils

final class MutexTests: XCTestCase {
    private struct TestError: Error, Equatable {}

    func testWithLockReturnsBodyResult() {
        let mutex = Mutex(1)

        let result = mutex.withLock { value in
            value += 1
            return value * 10
        }

        XCTAssertEqual(result, 20)
        XCTAssertEqual(mutex.value, 2)
    }

    func testWithLockRethrowsError() {
        let mutex = Mutex(0)

        XCTAssertThrowsError(try mutex.withLock { (value: inout Int) in
            value = 1
            throw TestError()
        }) { error in
            XCTAssertEqual(error as? TestError, TestError())
        }
        XCTAssertEqual(mutex.value, 1)
    }

    func testConcurrentIncrements() {
        let mutex = Mutex(0)

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            mutex.withLock { $0 += 1 }
        }

        XCTAssertEqual(mutex.value, 10_000)
    }
}
