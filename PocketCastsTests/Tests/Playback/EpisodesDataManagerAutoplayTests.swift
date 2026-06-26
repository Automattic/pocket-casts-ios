import XCTest

@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import podcasts

/// Regression tests for autoplay episode selection from manual playlists.
///
/// A manual playlist can contain episodes from podcasts the user does not follow.
/// Autoplay must play through the exact list shown on the playlist screen, including
/// those unfollowed-podcast episodes. Previously autoplay used a legacy query that
/// ignored `EpisodeFilter.manual` and excluded episodes from unsubscribed podcasts,
/// which made playback stop (the current/next episode was missing from the fetched
/// list) or jump to an unrelated episode.
final class EpisodesDataManagerAutoplayTests: XCTestCase {
    private var dataManager: DataManager!
    private let episodesDataManager = EpisodesDataManager()

    override func setUp() {
        super.setUp()
        dataManager = DataManager.newTestDataManager()
        DataManager.sharedManager = dataManager
    }

    func testManualPlaylistAutoplayIncludesEpisodesFromUnfollowedPodcasts() {
        // A followed podcast and an unfollowed one, each with a single episode.
        let followed = saveEpisode(uuid: "followed-ep", podcastUuid: "followed-pod", subscribed: true)
        let unfollowed = saveEpisode(uuid: "unfollowed-ep", podcastUuid: "unfollowed-pod", subscribed: false)

        let playlist = makeManualPlaylist(uuid: "manual-playlist")
        dataManager.save(playlist: playlist)
        XCTAssertTrue(dataManager.add(episodes: [followed, unfollowed], to: playlist))

        let episodes = episodesDataManager.episodes(for: .filter(uuid: playlist.uuid))

        XCTAssertEqual(episodes.map { $0.uuid }, ["followed-ep", "unfollowed-ep"],
                       "Autoplay should see every episode in the manual playlist, in order, including episodes from podcasts the user doesn't follow")
    }

    func testManualPlaylistAutoplayPlaysNextEpisodeFromUnfollowedPodcast() {
        let followed = saveEpisode(uuid: "current-ep", podcastUuid: "followed-pod", subscribed: true)
        let unfollowed = saveEpisode(uuid: "next-ep", podcastUuid: "unfollowed-pod", subscribed: false)

        let playlist = makeManualPlaylist(uuid: "manual-playlist")
        dataManager.save(playlist: playlist)
        XCTAssertTrue(dataManager.add(episodes: [followed, unfollowed], to: playlist))

        let userDefaults = UserDefaults(suiteName: "EpisodesDataManagerAutoplayTests")!
        userDefaults.removePersistentDomain(forName: "EpisodesDataManagerAutoplayTests")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
        let autoplayHelper = AutoplayHelper(userDefaults: userDefaults)
        autoplayHelper.playedFrom(playlist: .filter(uuid: playlist.uuid))

        let nextEpisode = autoplayHelper.nextEpisode(currentEpisodeUuid: "current-ep")

        XCTAssertEqual(nextEpisode?.uuid, "next-ep",
                       "When the current episode finishes, autoplay should queue the next episode in the manual playlist even if it is from an unfollowed podcast")
    }

    // MARK: - Helpers

    private func makeManualPlaylist(uuid: String) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = uuid
        playlist.playlistName = "Manual"
        // Order episodes by their position in the playlist, mirroring a real manual playlist.
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        return playlist
    }

    @discardableResult
    private func saveEpisode(uuid: String, podcastUuid: String, subscribed: Bool) -> Episode {
        let podcast = Podcast()
        podcast.uuid = podcastUuid
        podcast.subscribed = subscribed ? 1 : 0
        podcast.syncStatus = SyncStatus.synced.rawValue
        dataManager.save(podcast: podcast)

        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcastUuid
        episode.podcast_id = podcast.id
        episode.title = uuid
        episode.addedDate = Date()
        episode.publishedDate = Date()
        episode.downloadUrl = "https://example.com/\(uuid).mp3"
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        dataManager.save(episode: episode)

        return episode
    }
}
