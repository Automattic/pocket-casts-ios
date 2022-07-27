import XCTest

@testable import PocketCastsDataModel
@testable import podcasts

class HomeGridDataHelperTests: XCTestCase {
    // Given a folder and a podcast without a folder, sort them
    // based on `sortedPodcasts` order
    func testLatestEpisodeSort() {
        let podcastInFolder = PodcastBuilder().build()
        let folder = FolderBuilder().with(podcasts: [podcastInFolder]).build()
        let podcastNotInAFolder = PodcastBuilder().build()
        let sortedPodcasts = [podcastInFolder, podcastNotInAFolder]
        var gridItems = [HomeGridItem(podcast: podcastNotInAFolder), HomeGridItem(folder: folder)]

        gridItems.sort { item1, item2 in HomeGridDataHelper.latestEpisodeSort(item1: item1, item2: item2, sortedPodcasts: sortedPodcasts) }

        XCTAssertEqual(gridItems.first?.folder, folder)
        XCTAssertEqual(gridItems[1].podcast, podcastNotInAFolder)
    }

    // Given a folder, a podcast without a folder, and an empty folder
    // sort the empty folder on the end
    func testLatestEpisodeSortWithEmptyFolders() {
        let podcastInFolder = PodcastBuilder().build()
        let folder = FolderBuilder().with(podcasts: [podcastInFolder]).build()
        let podcastNotInAFolder = PodcastBuilder().build()
        let sortedPodcasts = [podcastInFolder, podcastNotInAFolder]
        let emptyFolder = FolderBuilder().build()
        var gridItems = [
            HomeGridItem(folder: emptyFolder),
            HomeGridItem(podcast: podcastNotInAFolder),
            HomeGridItem(folder: folder)
        ]

        gridItems.sort { item1, item2 in HomeGridDataHelper.latestEpisodeSort(item1: item1, item2: item2, sortedPodcasts: sortedPodcasts) }

        XCTAssertEqual(gridItems.first?.folder, folder)
        XCTAssertEqual(gridItems[1].podcast, podcastNotInAFolder)
        XCTAssertEqual(gridItems[2].folder, emptyFolder)
    }
}
