@testable import PocketCastsServer
import XCTest

final class AsyncLockTests: XCTestCase {
    func testWorkIsSerialisedAcrossSuspensionPoints() async {
        let lock = AsyncLock()
        let counter = Counter()

        // without the lock the read and the write below interleave and updates are lost
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    await lock.lock()
                    let value = await counter.value
                    await Task.yield()
                    await counter.set(value + 1)
                    await lock.unlock()
                }
            }
        }

        let value = await counter.value
        XCTAssertEqual(value, 10)
    }

    func testLockIsReleasedForTheNextCaller() async {
        let lock = AsyncLock()

        await lock.lock()
        await lock.unlock()

        // a second lock/unlock cycle would hang if the first one didn't release the lock
        await lock.lock()
        await lock.unlock()
    }
}

private actor Counter {
    private(set) var value = 0

    func set(_ newValue: Int) {
        value = newValue
    }
}
