import XCTest
@testable import PocketCastsDataModel

/// Stress tests that hammer the in-memory caches in `FolderDataManager` and
/// `UpNextDataManager` from several threads at once.
///
/// The reads used to happen outside the cache queue, so a reader could pick up a
/// collection buffer that the writer was releasing. Run these under the Thread
/// Sanitizer to catch a regression.
final class DataManagerConcurrencyTests: DataManagerTestCase {
    private let writeCount = 50
    private let readCount = 500
    private let timeout: TimeInterval = 60

    func testAllFoldersWhileFoldersAreSaved() {
        let dataManager = DataManager.newTestDataManager()
        for index in 0 ..< 5 {
            createFolder(name: "Folder \(index)", dataManager: dataManager)
        }

        runConcurrently(
            write: { index in
                self.createFolder(name: "Concurrent \(index)", dataManager: dataManager)
            },
            read: {
                for folder in dataManager.allFolders(includeDeleted: true) {
                    XCTAssertFalse(folder.uuid.isEmpty)
                }
            }
        )

        XCTAssertEqual(dataManager.allFolders(includeDeleted: true).count, 5 + writeCount)
    }

    func testUpNextEpisodesWhileEpisodesAreMoved() {
        let dataManager = DataManager.newTestDataManager()
        let podcast = createTestPodcast(dataManager: dataManager)
        for index in 0 ..< 5 {
            let episode = createTestEpisode(podcast: podcast, title: "Episode \(index)", dataManager: dataManager)
            addToUpNextBottom(episodeUuid: episode.uuid, title: episode.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
        }

        runConcurrently(
            write: { index in
                dataManager.movePlaylistEpisode(from: index % 5, to: (index + 1) % 5)
            },
            read: {
                for playlistEpisode in dataManager.allUpNextPlaylistEpisodes() {
                    XCTAssertFalse(playlistEpisode.episodeUuid.isEmpty)
                }
            }
        )

        XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 5)
    }

    // MARK: - Helpers

    private func runConcurrently(write: @escaping (Int) -> Void, read: @escaping () -> Void) {
        let writesFinished = expectation(description: "writes finished")
        let readsFinished = expectation(description: "reads finished")

        DispatchQueue.global().async {
            for index in 0 ..< self.writeCount {
                write(index)
            }
            writesFinished.fulfill()
        }

        DispatchQueue.global().async {
            for _ in 0 ..< self.readCount {
                read()
            }
            readsFinished.fulfill()
        }

        wait(for: [writesFinished, readsFinished], timeout: timeout)
    }

    private func createFolder(name: String, dataManager: DataManager) {
        let folder = Folder()
        folder.uuid = UUID().uuidString
        folder.name = name
        folder.addedDate = Date()
        dataManager.save(folder: folder)
    }
}
