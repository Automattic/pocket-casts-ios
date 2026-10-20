import XCTest

@testable import podcasts

final class HorizontalCollectionModelTests: XCTestCase {
    func testShowsACollectionWithASubtitle() {
        let model = populatedModel(subtitle: "Staff picks")

        XCTAssertFalse(model.isHidden)
        XCTAssertEqual(model.type, "Staff picks")
        XCTAssertEqual(model.list.count, 2)
    }

    func testHidesACollectionWithoutASubtitle() {
        XCTAssertTrue(populatedModel(subtitle: nil).isHidden)
    }

    func testHidesACollectionWithAnEmptySubtitle() {
        XCTAssertTrue(populatedModel(subtitle: "").isHidden)
    }

    func testHidesACollectionWithABlankSubtitle() {
        XCTAssertTrue(populatedModel(subtitle: " \n").isHidden)
    }

    func testShowsAnotherCollectionAfterAHiddenOne() {
        let model = populatedModel(subtitle: "")
        XCTAssertTrue(model.isHidden)

        populate(model, subtitle: "Staff picks")

        XCTAssertFalse(model.isHidden)
    }

    private func populatedModel(subtitle: String?) -> HorizontalCollectionModel {
        let model = HorizontalCollectionModel()
        populate(model, subtitle: subtitle)
        return model
    }

    private func populate(_ model: HorizontalCollectionModel, subtitle: String?) {
        model.serverHandler = PreviewDiscoverServerHandler(
            podcastCollection: DiscoverPreviewData.podcastCollection(
                title: "Sounds for sleeping",
                subtitle: subtitle,
                podcasts: DiscoverPreviewData.podcasts(4)
            )
        )
        model.populateFrom(item: DiscoverPreviewData.item(.collectionSummary, title: "Collection"), region: "us", category: nil)

        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }
}
