import XCTest

@testable import podcasts

class CreateFolderViewTests: XCTestCase {
    func testAddButtonTitleIsSkipWhenNoPodcastsAreSelected() {
        XCTAssertEqual(CreateFolderView.addButtonTitle(selectedCount: 0), L10n.folderCreateSkip)
    }

    func testAddButtonTitleForOneSelectedPodcast() {
        XCTAssertEqual(CreateFolderView.addButtonTitle(selectedCount: 1), L10n.folderAddPodcastsSingular)
    }

    func testAddButtonTitleForMultipleSelectedPodcasts() {
        XCTAssertEqual(CreateFolderView.addButtonTitle(selectedCount: 3), L10n.folderAddPodcastsPluralFormat(3))
    }
}
