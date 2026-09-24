import XCTest
import PocketCastsServer

@testable import podcasts

final class SearchResultsModelTests: XCTestCase {
    private var model: SearchResultsModel!

    override func setUp() {
        super.setUp()
        model = SearchResultsModel()
    }

    func testNoResultsIgnoresLeftoverPredictiveResultsWhenShowingFullResults() throws {
        model.predictive = try makePredictiveResults()
        model.isShowingPredictiveSearch = false

        XCTAssertTrue(model.noResults)
    }

    func testNoResultsIsFalseWhenShowingPredictiveResults() throws {
        model.predictive = try makePredictiveResults()
        model.isShowingPredictiveSearch = true

        XCTAssertFalse(model.noResults)
    }

    func testNoResultsIsTrueWhenPredictiveSearchFindsNothing() {
        model.isShowingPredictiveSearch = true

        XCTAssertTrue(model.noResults)
    }

    private func makePredictiveResults() throws -> [PredictiveSearchResult] {
        let json = #"[{"type": "term", "value": "zz top"}]"#
        return try JSONDecoder().decode([PredictiveSearchResult].self, from: Data(json.utf8))
    }
}
