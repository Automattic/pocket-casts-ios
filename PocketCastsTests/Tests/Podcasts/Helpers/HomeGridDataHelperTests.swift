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

    // Given a folder, a podcast without a folder and multiple empty folders
    // sort the empty folders using the title
    func testMultipleEmptyFolderNames() {
        let folderNames = [
            "Olá Mundo",
            "Powerلُلُصّبُلُلصّبُررً ॣ ॣh ॣ ॣ冗",
            "˙ɐnbᴉlɐ ɐuƃɐɯ ǝɹolop ʇǝ ǝɹoqɐl ʇn ʇunpᴉpᴉɔuᴉ ɹodɯǝʇ poɯsnᴉǝ op pǝs 'ʇᴉlǝ ƃuᴉɔsᴉdᴉpɐ ɹnʇǝʇɔǝsuoɔ 'ʇǝɯɐ ʇᴉs ɹolop ɯnsdᴉ ɯǝɹo˥ 00˙Ɩ$-",
            "ДSDӺДSDӺ",
            "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਦੁਨਿਆ",
            "🏳0🌈️",
            "🔛🔛🔛",
            "😀"
        ]
        let podcastInFolder = PodcastBuilder().build()
        let folder = FolderBuilder().with(podcasts: [podcastInFolder]).build()
        let podcastNotInAFolder = PodcastBuilder().build()
        let sortedPodcasts = [podcastInFolder, podcastNotInAFolder]
        var gridItems = [
            HomeGridItem(podcast: podcastNotInAFolder),
            HomeGridItem(folder: folder)
        ]
        gridItems.append(contentsOf: folderNames.shuffled().map { HomeGridItem(folder: FolderBuilder().with(name: $0).build()) })

        gridItems.sort { item1, item2 in HomeGridDataHelper.latestEpisodeSort(item1: item1, item2: item2, sortedPodcasts: sortedPodcasts) }

        XCTAssertEqual(gridItems.first?.folder, folder)
        XCTAssertEqual(gridItems[1].podcast, podcastNotInAFolder)
        XCTAssertEqual(gridItems[2].folder?.name, folderNames.first)
        XCTAssertEqual(gridItems[3].folder?.name, folderNames[1])
        XCTAssertEqual(gridItems[4].folder?.name, folderNames[2])
        XCTAssertEqual(gridItems[5].folder?.name, folderNames[3])
        XCTAssertEqual(gridItems[6].folder?.name, folderNames[4])
        XCTAssertEqual(gridItems[7].folder?.name, folderNames[5])
        XCTAssertEqual(gridItems[8].folder?.name, folderNames[6])
        XCTAssertEqual(gridItems[9].folder?.name, folderNames[7])
    }

    func testMergeKeepsHiddenItemsInPlace() {
        let merged = HomeGridDataHelper.merge(reorderedVisibleItems: ["c", "a"], into: ["a", "hidden", "c"], id: { $0 })

        XCTAssertEqual(merged, ["c", "hidden", "a"])
    }

    func testMergeWithoutHiddenItemsUsesVisibleOrder() {
        let merged = HomeGridDataHelper.merge(reorderedVisibleItems: ["c", "b", "a"], into: ["a", "b", "c"], id: { $0 })

        XCTAssertEqual(merged, ["c", "b", "a"])
    }

    func testMergeAppendsVisibleItemsMissingFromAllItems() {
        let merged = HomeGridDataHelper.merge(reorderedVisibleItems: ["new", "a"], into: ["a", "hidden"], id: { $0 })

        XCTAssertEqual(merged, ["new", "hidden", "a"])
    }
}
