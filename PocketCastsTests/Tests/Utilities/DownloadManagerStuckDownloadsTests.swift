import XCTest
@testable import podcasts
import PocketCastsDataModel

final class DownloadManagerStuckDownloadsTests: DBTestCase {

    override func tearDown() {
        super.tearDown()

        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await downloadManager.cancelAllTasks()
            downloadManager.clearEpisodeCache()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5.seconds)
    }

    func testClearStuckDownloadsKeepsRecentlyQueuedEpisode() async throws {
        queueEpisode(lastDownloadAttemptDate: Date())

        await downloadManager.clearStuckDownloads()

        let saved = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(saved.downloadTaskId, episode.uuid, "A download that hasn't created its task yet should not be treated as stuck")
        XCTAssertEqual(saved.episodeStatus, DownloadStatus.queued.rawValue)
    }

    func testClearStuckDownloadsClearsEpisodeWithoutRecentAttempt() async throws {
        queueEpisode(lastDownloadAttemptDate: Date().addingTimeInterval(-1.hour))

        await downloadManager.clearStuckDownloads()

        let saved = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertNil(saved.downloadTaskId)
        XCTAssertEqual(saved.episodeStatus, DownloadStatus.notDownloaded.rawValue)
    }

    func testPerformDownloadRestoresClearedDownloadTaskId() async throws {
        queueEpisode(lastDownloadAttemptDate: Date())

        // Simulate `clearStuckDownloads()` running while the download was still being prepared
        dataManager.saveEpisode(downloadStatus: .notDownloaded, downloadTaskId: nil, episode: episode)
        XCTAssertNil(dataManager.findBaseEpisode(downloadTaskId: episode.uuid))

        await downloadManager.performDownload(
            episode: episode,
            url: try XCTUnwrap(episode.downloadUrl),
            previousDownloadFailed: false,
            fireNotification: false,
            autoDownloadStatus: .notSpecified,
            retryWithoutUserAgent: false
        )

        let saved = try XCTUnwrap(dataManager.findBaseEpisode(downloadTaskId: episode.uuid))
        XCTAssertEqual(saved.uuid, episode.uuid, "The delegate callbacks look episodes up by downloadTaskId, so it has to match the running task")
    }

    private func queueEpisode(lastDownloadAttemptDate: Date) {
        episode.episodeStatus = DownloadStatus.queued.rawValue
        episode.downloadTaskId = episode.uuid
        episode.lastDownloadAttemptDate = lastDownloadAttemptDate
        dataManager.save(episode: episode)
    }
}
