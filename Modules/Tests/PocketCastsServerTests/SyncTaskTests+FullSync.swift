@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest
import GRDB

final class SyncTaskTests_FullSync: XCTestCase {
    private var dataManager: DataManager!
    private var syncTask: SyncTask!

    override func setUp() {
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try! DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
        syncTask = SyncTask(dataManager: dataManager)
        DataManager.shared = dataManager
    }

    func testRepeatFullSyncRestoresFolderAssignmentsOfSkippedPodcasts() {
        let lastSyncAt = "2026-10-14T14:58:47.830Z"
        let folderUuid = "folder-\(UUID().uuidString)"
        let podcastUuid = "podcast-\(UUID().uuidString)"

        let podcast = Podcast()
        podcast.uuid = podcastUuid
        podcast.fullSyncLastSyncAt = lastSyncAt
        podcast.folderUuid = folderUuid
        podcast.syncStatus = SyncStatus.synced.rawValue
        dataManager.save(podcast: podcast)

        let folder = FolderSyncInfo(uuid: folderUuid, name: "Folder", color: 0, sortOrder: 0, sortType: 0, addedDate: Date())
        let podcastInfo = PodcastSyncInfo(uuid: podcastUuid, folderUuid: folderUuid)

        syncTask.processServerHomeGrid(podcasts: [podcastInfo], folders: [folder], lastSyncAt: lastSyncAt)

        XCTAssertNotNil(dataManager.findFolder(uuid: folderUuid))
        XCTAssertEqual(dataManager.findPodcast(uuid: podcastUuid)?.folderUuid, folderUuid)
    }
}
