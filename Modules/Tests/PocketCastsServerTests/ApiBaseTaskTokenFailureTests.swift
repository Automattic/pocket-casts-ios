@testable import PocketCastsServer
import PocketCastsDataModel
import XCTest

final class ApiBaseTaskTokenFailureTests: XCTestCase {
    func testWinbackOfferTaskCompletesWithNilWhenTokenAcquisitionFails() {
        let task = TokenlessWinbackOfferTask()
        var completionCount = 0
        var offer: WinbackOfferInfo?
        task.completion = {
            completionCount += 1
            offer = $0
        }

        task.runTaskSynchronously()

        XCTAssertEqual(completionCount, 1)
        XCTAssertNil(offer)
    }

    func testSubscriptionStatusTaskCompletesWithFalseWhenTokenAcquisitionFails() {
        let task = TokenlessSubscriptionStatusTask()
        var results: [Bool] = []
        task.completion = { results.append($0) }

        task.runTaskSynchronously()

        XCTAssertEqual(results, [false])
    }

    func testUserPodcastRatingGetTaskCompletesWithFailureWhenTokenAcquisitionFails() {
        let task = TokenlessUserPodcastRatingGetTask(uuid: "podcast")
        var completionCount = 0
        var success: Bool?
        var rating: UserPodcastRating?
        task.completion = {
            completionCount += 1
            success = $0
            rating = $1
        }

        task.runTaskSynchronously()

        XCTAssertEqual(completionCount, 1)
        XCTAssertEqual(success, false)
        XCTAssertNil(rating)
    }
}

private final class TokenlessWinbackOfferTask: WinbackOfferTask, @unchecked Sendable {
    override func acquiredToken() -> String? { nil }
}

private final class TokenlessSubscriptionStatusTask: SubscriptionStatusTask, @unchecked Sendable {
    override func acquiredToken() -> String? { nil }
}

private final class TokenlessUserPodcastRatingGetTask: UserPodcastRatingGetTask, @unchecked Sendable {
    override func acquiredToken() -> String? { nil }
}
