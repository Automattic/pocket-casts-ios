import XCTest
@testable import podcasts

final class ListeningHistoryContentStateTests: XCTestCase {

    // MARK: - Bug Fix: PCIOS-897
    // Listening History showed the "No episodes found" empty state while the first search of the
    // session was still running, because the state was derived from the row count alone.

    func testShowsLoadingWhileTheSearchIsStillRunning() {
        let state = ListeningHistoryContentState(isEmpty: true, hasLoaded: false, isSearching: true)

        XCTAssertEqual(state, .loading, "A search that hasn't finished should show a loading indicator, not an empty state")
    }

    func testShowsNoSearchResultsOnceTheSearchHasFinished() {
        let state = ListeningHistoryContentState(isEmpty: true, hasLoaded: true, isSearching: true)

        XCTAssertEqual(state, .noSearchResults)
    }

    func testShowsLoadingWhileTheHistoryIsStillLoading() {
        let state = ListeningHistoryContentState(isEmpty: true, hasLoaded: false, isSearching: false)

        XCTAssertEqual(state, .loading)
    }

    func testShowsNoHistoryOnceTheHistoryHasLoaded() {
        let state = ListeningHistoryContentState(isEmpty: true, hasLoaded: true, isSearching: false)

        XCTAssertEqual(state, .noHistory)
    }

    func testShowsContentWheneverThereAreEpisodes() {
        for hasLoaded in [true, false] {
            for isSearching in [true, false] {
                let state = ListeningHistoryContentState(isEmpty: false, hasLoaded: hasLoaded, isSearching: isSearching)

                XCTAssertEqual(state, .content, "Episodes should stay on screen while another load runs (hasLoaded: \(hasLoaded), isSearching: \(isSearching))")
            }
        }
    }
}
