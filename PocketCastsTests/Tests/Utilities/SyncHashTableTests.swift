import XCTest

@testable import podcasts

final class SyncHashTableTests: XCTestCase {

    func testThreadSafety() async {
        let dictionary = SyncHashTable<String, String>()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1_000_000 {
                group.addTask {
                    let uuid = UUID().uuidString
                    dictionary[uuid] = uuid
                    dictionary[uuid] = nil
                }
            }
        }
    }
}
