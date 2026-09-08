import Combine
import SwiftUI
import XCTest

@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// The header's category and author line, and the details box below it: what each part is, and
/// where tapping it goes.
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

    func testTheDetailsAuthorOpensTheNetworkThePodcastBelongsTo() {
        let delegate = PodcastActionsDelegateMock()
        let viewModel = viewModel(networkListId: "cdb75bc0-9f5a-4217-b1ca-f573821a7913", delegate: delegate)

        viewModel.networkTapped()

        XCTAssertEqual(delegate.networksShown, ["cdb75bc0-9f5a-4217-b1ca-f573821a7913"])
    }

    func testTheDetailsAuthorOfAPodcastWithoutANetworkGoesNowhere() {
        let delegate = PodcastActionsDelegateMock()
        let viewModel = viewModel(networkListId: nil, delegate: delegate)

        XCTAssertNil(viewModel.networkListId, "Without a network the author is drawn as plain text")

        viewModel.networkTapped()

        XCTAssertTrue(delegate.networksShown.isEmpty)
    }

    func testTheDetailsAuthorGoesNowhereWhileTheAppDoesNotShowNetworks() {
        featureFlagMock.set(.networkDiscovery, value: false)

        let delegate = PodcastActionsDelegateMock()
        let viewModel = viewModel(networkListId: "cdb75bc0-9f5a-4217-b1ca-f573821a7913", delegate: delegate)

        XCTAssertNil(viewModel.networkListId)

        viewModel.networkTapped()

        XCTAssertTrue(delegate.networksShown.isEmpty)
    }

    func testALinkIsRecognisedFromItsURL() {
        XCTAssertEqual(PodcastHeaderLink(url: PodcastHeaderLink.category.url), .category)
        XCTAssertEqual(PodcastHeaderLink(url: PodcastHeaderLink.author.url), .author)
        XCTAssertNil(PodcastHeaderLink(url: URL(string: "https://pocketcasts.com")!))
    }

    // MARK: - Helpers

    private func viewModel(networkListId: String?, delegate: PodcastActionsDelegate? = nil) -> PodcastHeaderViewModel {
        let podcast = Podcast()
        podcast.podcastCategory = "Technology"
        podcast.author = "Relay"
        podcast.networkListId = networkListId

        return PodcastHeaderViewModel(podcast: podcast, delegate: delegate)
    }

    private func text(of line: AttributedString, linkedTo link: PodcastHeaderLink) -> String? {
        guard let run = line.runs.first(where: { $0.link == link.url }) else { return nil }

        return String(line[run.range].characters)
    }
}

/// A delegate that records the networks it was asked to open and does nothing else.
private final class PodcastActionsDelegateMock: PodcastActionsDelegate {
    private(set) var networksShown: [String] = []

    func networkTapped(listId: String) {
        networksShown.append(listId)
    }

    var hasSimilarShowsPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
    var currentViewModePublisher: AnyPublisher<PodcastViewController.ViewMode, Never> { Just(.episodes).eraseToAnyPublisher() }
    var podcastRatingViewModel = PodcastRatingViewModel()
    var ratingView = UIView()

    func isSummaryExpanded() -> Bool { false }
    func setSummaryExpanded(expanded: Bool) {}
    func isDescriptionExpanded() -> Bool { false }
    func setDescriptionExpanded(expanded: Bool) {}
    func tableView() -> UITableView { UITableView() }
    func displayedPodcast() -> Podcast? { nil }
    func manageSubscriptionTapped() {}
    func settingsTapped() {}
    func fundingTapped() {}
    func folderTapped() {}
    func notificationTapped() {}
    func categoryTapped(_ category: String) {}
    func subscribe() {}
    func unsubscribe() {}
    func refreshArtwork() {}
    func showBookmarks() {}
    func showEpisodes() {}
    func showYouMightLike() {}
    func showLogin(message: String?) {}
    func open(url: URL) {}
}
