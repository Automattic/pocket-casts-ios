import Combine
import PocketCastsServer
import XCTest

@testable import podcasts

/// What the networks row shows of a `lists_list`: the first few networks, the rest behind "Show all".
final class DiscoverNetworksListModelTests: XCTestCase {
    private var serverHandler: StubDiscoverServerHandler!
    private var model: DiscoverNetworksListModel!

    override func setUp() {
        super.setUp()

        serverHandler = StubDiscoverServerHandler()
        model = DiscoverNetworksListModel()
        model.serverHandler = serverHandler
    }

    override func tearDown() {
        model = nil
        serverHandler = nil

        super.tearDown()
    }

    func testShowsTenNetworksAtMost() {
        serverHandler.collection = collection(networkCount: 14)

        populate()

        XCTAssertEqual(model.visibleNetworks.map(\.title), (0..<10).map { "Network \($0)" })
    }

    func testKeepsEveryNetworkForShowAll() {
        serverHandler.collection = collection(networkCount: 14)

        populate()

        XCTAssertEqual(model.networks.count, 14, "The expanded grid shows the networks the row leaves out")
    }

    func testShowsEveryNetworkWhenThereAreFewerThanTheLimit() {
        serverHandler.collection = collection(networkCount: 6)

        populate()

        XCTAssertEqual(model.visibleNetworks.count, 6)
    }

    func testShowsNothingUntilTheNetworksLoad() {
        XCTAssertTrue(model.visibleNetworks.isEmpty)
    }

    func testTheLayoutCanAskForADifferentNumber() {
        serverHandler.collection = collection(networkCount: 14)

        populate(summaryItemCount: 3)

        XCTAssertEqual(model.visibleNetworks.map(\.title), ["Network 0", "Network 1", "Network 2"])
    }

    func testTheLayoutAskingForNoneShowsNone() {
        serverHandler.collection = collection(networkCount: 14)

        populate(summaryItemCount: 0)

        XCTAssertTrue(model.visibleNetworks.isEmpty)
    }

    func testTheLayoutAskingForMoreThanThereAreShowsThemAll() {
        serverHandler.collection = collection(networkCount: 6)

        populate(summaryItemCount: 20)

        XCTAssertEqual(model.visibleNetworks.count, 6)
    }

    // MARK: - Helpers

    private func populate(summaryItemCount: Int? = nil) {
        model.populateFrom(
            item: DiscoverItem(
                id: "networks",
                uuid: "networks",
                title: "Networks",
                type: "lists_list",
                summaryStyle: "lists_list",
                summaryItemCount: summaryItemCount,
                expandedStyle: "network_grid",
                source: "https://lists.pocketcasts.com/networks.json",
                regions: ["us"]
            ),
            region: "us",
            category: nil
        )
        drainMainQueue()
    }

    private func collection(networkCount: Int) -> PodcastCollection {
        let lists = (0..<networkCount).map { index in
            """
            {
                "uuid": "network-\(index)",
                "title": "Network \(index)",
                "type": "\(NetworkListSummary.supportedType)",
                "summary_style": "collection",
                "expanded_style": "network_grid",
                "source": "https://lists.pocketcasts.com/network-\(index).json"
            }
            """
        }
        let json = """
        {"list_id": "networks", "title": "Networks", "lists": [\(lists.joined(separator: ","))]}
        """

        return try! JSONDecoder().decode(PodcastCollection.self, from: Data(json.utf8))
    }

    /// Waits for the work the model hops to the main queue, which runs after the test's own turn.
    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }
}

private final class StubDiscoverServerHandler: DiscoverServerHandling {
    var collection: PodcastCollection?

    func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        completion(collection)
    }

    func discoverPodcastList(source: String, authenticated: Bool?, completion: @escaping (PodcastList?) -> Void) {
        completion(nil)
    }

    func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
        []
    }

    func discoverCategories(source: String, authenticated: Bool?, completion: @escaping ([DiscoverCategory]?) -> Void) {
        completion(nil)
    }

    func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        completion(nil)
    }

    func discoverItem<T>(_ source: String?, authenticated: Bool, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        Empty().eraseToAnyPublisher()
    }
}
