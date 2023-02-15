#if DEBUG
    #if canImport(AudioToolbox)
    import AudioToolbox
    #endif
#endif

import Foundation
import PocketCastsDataModel
import PocketCastsUtils

struct BookmarkManager {
    typealias Bookmark = BookmarkDataManager.Bookmark

    private let dataManager = DataManager.sharedManager.bookmarks

    /// Plays the "bookmark created" tone
    private lazy var tonePlayer: AVAudioPlayer? = {
        guard
            let url = Bundle.main.url(forResource: "TODO", withExtension: "TODO"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else {
            return nil
        }

        player.prepareToPlay()
        return player
    }()

    /// How long a bookmark clip is
    /// TODO: Make configurable
    private let clipLength = 1.minute

    /// Adds a new bookmark for an episode at the given time
    func add(to episode: BaseEpisode, at time: TimeInterval) {
        // If the episode has a podcast attached, also save that
        let podcastUuid: String? = (episode as? Episode)?.podcastUuid

        // If someone is bookmarking a point in time, they probably want to remember the info leading up to the bookmark
        // time, so calculate the start of the clip as X seconds before the bookmark time
        let startTime = max(0, time - clipLength)

        dataManager.add(episodeUuid: episode.uuid, podcastUuid: podcastUuid, start: startTime, end: time)

        playTone()

        FileLog.shared.addMessage("[Bookmarks] Added bookmark for \(episode.displayableTitle()) from \(startTime) to \(time)")
    }

    /// Retrieves all the bookmarks for a episode
    func bookmarks(for episode: BaseEpisode) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: episode.uuid)
    }

    /// Retrieves all the bookmarks for a podcast
    func bookmarks(for podcast: Podcast) -> [Bookmark] {
        dataManager.bookmarks(forEpisode: podcast.uuid)
    }
}

// MARK: - Private
private extension BookmarkManager {
    func playTone() {
        // TODO: This is temporary until we have the actual sound file
        #if DEBUG
            #if !os(watchOS)
            // This just plays a system sound instead.
            if let url = FileManager.default.urls(for: .libraryDirectory, in: .systemDomainMask).first {
                let audioFile = url.appendingPathComponent("Audio/UISounds/PINSubmit_AX.caf")
                var soundID: SystemSoundID = .zero
                AudioServicesCreateSystemSoundID(audioFile as CFURL, &soundID)
                AudioServicesPlaySystemSoundWithCompletion(soundID) {
                    AudioServicesDisposeSystemSoundID(soundID)
                    AudioServicesRemoveSystemSoundCompletion(soundID)
                }
            }
            #endif
        #else
        // Stop playing immediately and reset to 0
        tonePlayer?.pause()
        tonePlayer?.currentTime = 0

        // Play
        tonePlayer?.play()
        #endif
    }
}
