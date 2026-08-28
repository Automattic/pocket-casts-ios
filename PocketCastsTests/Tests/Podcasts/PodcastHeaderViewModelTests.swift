import SwiftUI
import XCTest

@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// The header's category and author line: what each part is, and where tapping it goes.
final class PodcastHeaderViewModelTests: XCTestCase {
    private let featureFlagMock = FeatureFlagMock()

    override func setUp() {
        super.setUp()
        featureFlagMock.set(.networkDiscovery, value: true)
    }

    override func tearDown() {
        featureFlagMock.reset()
        super.tearDown()
    }

    func testTheAuthorOpensTheNetworkThePodcastBelongsTo() {
        let line = viewModel(networkListId: "cdb75bc0-9f5a-4217-b1ca-f573821a7913").displayCategoryAndAuthor(networkTint: .red)

        XCTAssertEqual(text(of: line, linkedTo: .category), "Technology")
        XCTAssertEqual(text(of: line, linkedTo: .author), "Relay")
    }

    func testTheAuthorOfAPodcastWithoutANetworkIsPlainText() {
        let line = viewModel(networkListId: nil).displayCategoryAndAuthor(networkTint: .red)

        XCTAssertEqual(String(line.characters), "Technology · Relay")
        XCTAssertNil(text(of: line, linkedTo: .author))
    }

    func testANetworkIsOnlyOfferedWhileTheAppShowsNetworks() {
        featureFlagMock.set(.networkDiscovery, value: false)

        let line = viewModel(networkListId: "cdb75bc0-9f5a-4217-b1ca-f573821a7913").displayCategoryAndAuthor(networkTint: .red)

        XCTAssertNil(text(of: line, linkedTo: .author))
    }

    func testTheNetworkIsDrawnInThePodcastsOwnColour() {
        let line = viewModel(networkListId: "cdb75bc0-9f5a-4217-b1ca-f573821a7913").displayCategoryAndAuthor(networkTint: .red)

        let author = line.runs.first { $0.link == PodcastHeaderLink.author.url }
        XCTAssertEqual(author?.foregroundColor, .red)
    }

    func testALinkIsRecognisedFromItsURL() {
        XCTAssertEqual(PodcastHeaderLink(url: PodcastHeaderLink.category.url), .category)
        XCTAssertEqual(PodcastHeaderLink(url: PodcastHeaderLink.author.url), .author)
        XCTAssertNil(PodcastHeaderLink(url: URL(string: "https://pocketcasts.com")!))
    }

    // MARK: - Helpers

    private func viewModel(networkListId: String?) -> PodcastHeaderViewModel {
        let podcast = Podcast()
        podcast.podcastCategory = "Technology"
        podcast.author = "Relay"
        podcast.networkListId = networkListId

        return PodcastHeaderViewModel(podcast: podcast)
    }

    private func text(of line: AttributedString, linkedTo link: PodcastHeaderLink) -> String? {
        guard let run = line.runs.first(where: { $0.link == link.url }) else { return nil }

        return String(line[run.range].characters)
    }
}
