@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB

final class SyncTaskPlaylistOrderingTests: XCTestCase {
    private var originalDataManager: DataManager!
    private var dataManager: CapturingDataManager!
    private var syncTask: SyncTask!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalDataManager = DataManager.sharedManager
        dataManager = CapturingDataManager()
        DataManager.sharedManager = dataManager

        syncTask = SyncTask(dataManager: dataManager)
    }

    override func tearDownWithError() throws {
        DataManager.sharedManager = originalDataManager
        syncTask = nil
        dataManager = nil
        originalDataManager = nil

        try super.tearDownWithError()
    }

    func testProcessServerPlaylistsAddsMissingEpisodesInServerOrder() {
        let playlistUuid = "playlist-order"

        let existing = makeEpisode(uuid: "ep-1")
        let fromServer = [existing, makeEpisode(uuid: "ep-2"), makeEpisode(uuid: "ep-3")]

        dataManager.stubbedPlaylistEpisodes[playlistUuid] = [existing]

        let playlist = makePlaylist(uuid: playlistUuid)
        syncTask.processServerPlaylists([(playlist, fromServer)])

        let addedEpisodes = dataManager.addedEpisodes[playlistUuid] ?? []
        XCTAssertEqual(addedEpisodes.map(\.uuid), ["ep-2", "ep-3"])
    }

    func testProcessServerPlaylistsDoesNotAddEpisodesWhenAlreadyPresent() {
        let playlistUuid = "playlist-no-add"

        let e1 = makeEpisode(uuid: "ep-a")
        let e2 = makeEpisode(uuid: "ep-b")

        dataManager.stubbedPlaylistEpisodes[playlistUuid] = [e1, e2]

        let playlist = makePlaylist(uuid: playlistUuid)
        syncTask.processServerPlaylists([(playlist, [e1, e2])])

        let addedEpisodes = dataManager.addedEpisodes[playlistUuid] ?? []
        XCTAssertTrue(addedEpisodes.isEmpty)
    }

    // MARK: - Helpers

    private func makePlaylist(uuid: String) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.uuid = uuid
        playlist.playlistName = "Playlist-\(uuid)"
        playlist.manual = false
        return playlist
    }

    private func makeEpisode(uuid: String) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = "pod-\(uuid)"
        episode.title = "Episode-\(uuid)"
        return episode
    }
}

private final class CapturingDataManager: DataManager {
    var stubbedPlaylistEpisodes: [String: [Episode]] = [:]
    var addedEpisodes: [String: [Episode]] = [:]
    private var storedPlaylists: [String: EpisodeFilter] = [:]

    init() {
        let dbPath = NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite")
        let pool = try! DatabasePool(path: dbPath)
        super.init(dbQueue: GRDBQueue(dbPool: pool, logger: DataManager.logger))
    }

    override func markAllPlaylistsUnsynced() {}

    override func findPlaylist(uuid: String) -> EpisodeFilter? {
        storedPlaylists[uuid]
    }

    override func delete(playlist: EpisodeFilter) {
        storedPlaylists.removeValue(forKey: playlist.uuid)
        addedEpisodes.removeValue(forKey: playlist.uuid)
    }

    override func playlistEpisodes(for playlist: EpisodeFilter) -> [Episode] {
        stubbedPlaylistEpisodes[playlist.uuid] ?? []
    }

    override func save(playlist: EpisodeFilter) {
        storedPlaylists[playlist.uuid] = playlist
    }

    override func add(episodes: [Episode], to playlist: EpisodeFilter) {
        addedEpisodes[playlist.uuid] = episodes
    }
}
