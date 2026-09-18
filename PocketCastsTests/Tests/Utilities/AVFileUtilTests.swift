import XCTest

@testable import podcasts

final class AVFileUtilTests: XCTestCase {

    func testLoadsEmbeddedTitleArtworkAndDuration() throws {
        let result = load(try resourceURL("with-title-and-artwork"), expectingOnly: [.title, .artwork, .duration])

        XCTAssertEqual(result.title, "Embedded Title Test")
        XCTAssertEqual(result.artwork?.size, CGSize(width: 600, height: 600))
        XCTAssertEqual(try XCTUnwrap(result.duration), 13.14, accuracy: 0.01)
    }

    func testFileWithoutMetadataReportsNoTitleOrArtwork() throws {
        let result = load(try resourceURL("no-metadata"), expectingOnly: [.title, .artwork, .duration])

        XCTAssertNil(result.title)
        XCTAssertNil(result.artwork)
        XCTAssertEqual(try XCTUnwrap(result.duration), 13.14, accuracy: 0.01)
    }

    func testMissingFileReportsNilTitleOnly() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")

        let result = load(url, expectingOnly: [.title])

        XCTAssertNil(result.title)
    }

    // MARK: - Helpers

    private enum Handler: CaseIterable {
        case title, artwork, duration
    }

    private final class LoadedMetadata {
        var title: String?
        var artwork: UIImage?
        var duration: TimeInterval?
    }

    private func resourceURL(_ name: String) throws -> URL {
        try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "m4a"))
    }

    private func load(_ url: URL, expectingOnly expected: Set<Handler>) -> LoadedMetadata {
        let result = LoadedMetadata()
        let expectations = Dictionary(uniqueKeysWithValues: Handler.allCases.map { handler in
            let expectation = expectation(description: "\(handler) handler")
            expectation.isInverted = !expected.contains(handler)
            return (handler, expectation)
        })

        let util = AVFileUtil(fileURL: url, durationHandler: { duration in
            result.duration = duration
            expectations[.duration]?.fulfill()
        }, titleHandler: { title in
            result.title = title
            expectations[.title]?.fulfill()
        }, artworkHandler: { artwork in
            result.artwork = artwork
            expectations[.artwork]?.fulfill()
        })

        withExtendedLifetime(util) {
            wait(for: expectations.values.filter { !$0.isInverted }, timeout: 10)
            let unexpected = expectations.values.filter(\.isInverted)
            if !unexpected.isEmpty {
                wait(for: unexpected, timeout: 1)
            }
        }
        return result
    }
}
