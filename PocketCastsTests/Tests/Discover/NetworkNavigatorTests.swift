import Combine
import UIKit
import XCTest

@testable import podcasts
@testable import PocketCastsServer

/// Opening a network: one screen per tap, and nothing for a tap the user moved on from.
final class NetworkNavigatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: RecordingNavigationController!
    private var host: UIViewController!
    private var presenter: UIViewController!
    private var serverHandler: MockDiscoverServerHandler!
    private var navigator: NetworkNavigator!

    private let listId = "c73d120f-c174-4324-b0a3-18f9b239a59d"
    private let otherListId = "cdb75bc0-9f5a-4217-b1ca-f573821a7913"

    private var source: String { ServerHelper.listUrlString(listId: listId) }
    private var otherSource: String { ServerHelper.listUrlString(listId: otherListId) }

    override func setUp() {
        super.setUp()

        // The screen asking for a network can be a child of the one on the stack — search is,
        // presented by Discover and by the podcast list — so the stack pushed onto is the host's.
        host = UIViewController()
        navigationController = RecordingNavigationController()
        navigationController.setViewControllers([host], animated: false)

        presenter = UIViewController()
        host.addChild(presenter)
        host.view.addSubview(presenter.view)
        presenter.didMove(toParent: host)

        // The asking screen on screen: the navigator only pushes while its view is in a window,
        // and the stack only puts its top screen's view there when it lays out.
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        XCTAssertNotNil(presenter.viewIfLoaded?.window, "The screen has to start on screen for any of this to be about the navigator")

        serverHandler = MockDiscoverServerHandler()
        navigator = NetworkNavigator(source: .discover, serverHandler: serverHandler)
        navigator.presenter = presenter
    }

    override func tearDown() {
        Toast.dismiss()
        window.isHidden = true
        window = nil
        navigationController = nil
        host = nil
        presenter = nil
        navigator = nil
        serverHandler = nil

        super.tearDown()
    }

    func testShowsTheNetworksList() throws {
        navigator.show(listId: listId)
        serverHandler.complete(at: 0, with: collection())
        drainMainQueue()

        let pushed = try XCTUnwrap(navigationController.pushedViewControllers.first as? ExpandedCollectionViewController)
        XCTAssertEqual(navigationController.pushedViewControllers.count, 1)
        XCTAssertEqual(serverHandler.requestedSources, [source])
        XCTAssertEqual(pushed.item.uuid, listId)
        XCTAssertEqual(pushed.item.expandedStyle, "grid")
    }

    func testTappingTheSameNetworkTwiceLoadsAndShowsItOnce() {
        navigator.show(listId: listId)
        navigator.show(listId: listId)

        XCTAssertEqual(serverHandler.requestedSources, [source], "The second tap joins the request already in flight")

        serverHandler.complete(at: 0, with: collection())
        drainMainQueue()

        XCTAssertEqual(navigationController.pushedViewControllers.count, 1)
    }

    func testASupersededNetworkIsNotShown() throws {
        navigator.show(listId: listId)
        navigator.show(listId: otherListId)

        XCTAssertEqual(serverHandler.requestedSources, [source, otherSource])

        serverHandler.complete(at: 0, with: collection())
        drainMainQueue()

        XCTAssertTrue(navigationController.pushedViewControllers.isEmpty, "The first network's late response is dropped")

        serverHandler.complete(at: 1, with: collection())
        drainMainQueue()

        let pushed = try XCTUnwrap(navigationController.pushedViewControllers.first as? ExpandedCollectionViewController)
        XCTAssertEqual(navigationController.pushedViewControllers.count, 1)
        XCTAssertEqual(pushed.item.uuid, otherListId)
    }

    func testNothingIsShownOnceTheScreenHasGoneAway() {
        navigator.show(listId: listId)

        // Dismissing search takes its view off screen, as does pushing another screen over it.
        presenter.view.removeFromSuperview()

        serverHandler.complete(at: 0, with: collection())
        drainMainQueue()

        XCTAssertTrue(navigationController.pushedViewControllers.isEmpty)
    }

    func testAFailedLoadCanBeTappedAgain() {
        navigator.show(listId: listId)
        serverHandler.complete(at: 0, with: nil)
        drainMainQueue()

        XCTAssertTrue(navigationController.pushedViewControllers.isEmpty)

        navigator.show(listId: listId)

        XCTAssertEqual(serverHandler.requestedSources, [source, source])

        serverHandler.complete(at: 1, with: collection())
        drainMainQueue()

        XCTAssertEqual(navigationController.pushedViewControllers.count, 1)
    }

    func testACallerThatKnowsTheNetworksNameUsesIt() throws {
        navigator.show(listId: listId, title: "WNYC")
        serverHandler.complete(at: 0, with: collection(title: "WNYC Studios"))
        drainMainQueue()

        let pushed = try XCTUnwrap(navigationController.pushedViewControllers.first as? ExpandedCollectionViewController)
        XCTAssertEqual(pushed.item.title, "WNYC")
    }

    func testANetworkNamesItselfForACallerThatDoesnt() throws {
        navigator.show(listId: listId)
        serverHandler.complete(at: 0, with: collection(title: "WNYC Studios"))
        drainMainQueue()

        let pushed = try XCTUnwrap(navigationController.pushedViewControllers.first as? ExpandedCollectionViewController)
        XCTAssertEqual(pushed.item.title, "WNYC Studios")
    }

    // MARK: - Helpers

    private func collection(title: String? = nil) -> PodcastCollection {
        var collection = try! JSONDecoder().decode(PodcastCollection.self, from: Data(#"{"podcasts": []}"#.utf8))
        collection.title = title
        return collection
    }

    /// Waits for the work the navigator hops to the main queue, which runs after the test's own turn.
    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }
}

private final class RecordingNavigationController: UINavigationController {
    private(set) var pushedViewControllers: [UIViewController] = []

    /// Records the push without performing it, so the pushed screen's view is never loaded. The
    /// root is set with `setViewControllers`, which doesn't come through here.
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushedViewControllers.append(viewController)
    }
}

private final class MockDiscoverServerHandler: DiscoverServerHandling {
    private(set) var requestedSources: [String] = []
    private var completions: [(PodcastCollection?) -> Void] = []

    func complete(at index: Int, with collection: PodcastCollection?) {
        completions[index](collection)
    }

    func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        requestedSources.append(source)
        completions.append(completion)
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
