import Foundation
@testable import PocketCastsServer
import XCTest

final class PodcastFolderSearchResultTests: XCTestCase {

    // MARK: - Hashable

    func testResultsForTheSamePodcastHashTheSame() throws {
        let remote = try makeResult(uuid: "uuid", title: "Planet Money", author: "NPR", isLocal: false)
        let local = try makeResult(uuid: "uuid", title: "Planet Money 2", author: "", isLocal: true)

        XCTAssertEqual(remote, local)
        XCTAssertEqual(remote.hashValue, local.hashValue)
    }

    func testSetKeepsOneOfTwoResultsForTheSamePodcast() throws {
        let remote = try makeResult(uuid: "uuid", title: "Planet Money", author: "NPR", isLocal: false)
        let local = try makeResult(uuid: "uuid", title: "Planet Money 2", author: "", isLocal: true)

        XCTAssertEqual(Set([remote, local]).count, 1)
    }

    func testAPodcastAndAFolderWithTheSameUUIDStayDistinct() throws {
        let podcast = try makeResult(uuid: "uuid", title: "Planet Money", kind: .podcast)
        let folder = try makeResult(uuid: "uuid", title: "Planet Money", kind: .folder)

        XCTAssertNotEqual(podcast, folder)
        XCTAssertEqual(Set([podcast, folder]).count, 2)
    }

    // MARK: - Deduplication

    func testDeduplicatedKeepsTheFirstOfEachRepeatedResult() throws {
        let first = try makeResult(uuid: "1", title: "Planet Money", author: "NPR")
        let repeated = try makeResult(uuid: "1", title: "Planet Money", author: "NPR Inc")
        let second = try makeResult(uuid: "2", title: "99% Invisible")

        let results = PodcastSearchTask.deduplicated([first, repeated, second])

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.map(\.uuid), ["1", "2"])
        XCTAssertEqual(results.first?.author, "NPR")
    }

    func testDeduplicatedLeavesDistinctResultsUntouched() throws {
        let results = try [
            makeResult(uuid: "1", title: "Planet Money"),
            makeResult(uuid: "2", title: "99% Invisible"),
            makeResult(uuid: "3", title: "Radiolab")
        ]

        XCTAssertEqual(PodcastSearchTask.deduplicated(results).map(\.uuid), ["1", "2", "3"])
    }

    func testDeduplicatedOnEmptyResults() {
        XCTAssertTrue(PodcastSearchTask.deduplicated([]).isEmpty)
    }

    // MARK: - Helpers

    /// Builds a result the way the search API does: by decoding it.
    private func makeResult(
        uuid: String,
        title: String,
        author: String = "",
        kind: PodcastFolderSearchResult.Kind = .podcast,
        isLocal: Bool = false
    ) throws -> PodcastFolderSearchResult {
        let payload = Payload(uuid: uuid, title: title, author: author, kind: kind, isLocal: isLocal)
        let data = try JSONEncoder().encode(payload)
        return try JSONDecoder().decode(PodcastFolderSearchResult.self, from: data)
    }

    private struct Payload: Encodable {
        let uuid: String
        let title: String
        let author: String
        let kind: PodcastFolderSearchResult.Kind
        let isLocal: Bool
    }
}
