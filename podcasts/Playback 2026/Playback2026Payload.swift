import Foundation
import PlaybackKit
import PocketCastsDataModel
import PocketCastsServer

/// Builds the facts PlaybackKit needs from the user's listening history.
///
/// The experience computes everything derived (top shows, best month, comparison, archetype)
/// itself, so this only supplies facts.
enum Playback2026Payload {
    static func make(year: Int, dataManager: DataManager = .shared) -> PlaybackPayload {
        let podcasts = dataManager.playbackPodcastStats(in: year).map { stats in
            PlaybackPayload.Podcast(
                uuid: stats.uuid,
                title: stats.title,
                author: stats.author,
                genre: stats.genre.flatMap { $0.isEmpty ? nil : $0 } ?? "Other",
                artworkUrl: ServerHelper.imageUrl(podcastUuid: stats.uuid, size: 400).absoluteString,
                playedSeconds: stats.playedSeconds,
                episodesPlayed: stats.episodesPlayed
                // TODO: `listenerCount` and `earlyFollower` come from the backend (POC-1007). Until then the
                // Collector and Avant-gardist archetypes can't be earned and the simplified rules pick from
                // the rest.
            )
        }

        let previousYearSeconds = dataManager.yearOverYearListeningTime(in: year).totalPlayedTimeLastYear
        let started = dataManager.playbackEpisodesStartedAndCompleted(in: year)

        return PlaybackPayload(
            year: year,
            podcasts: podcasts,
            monthlySeconds: dataManager.playbackMonthlySeconds(in: year),
            previousYearSeconds: previousYearSeconds > 0 ? previousYearSeconds : nil,
            completion: started.started > 0 ? .init(started: started.started, completed: started.completed) : nil
        )
    }
}
