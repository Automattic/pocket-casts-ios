import Foundation
import PlaybackKit
import PocketCastsDataModel
import PocketCastsServer

/// Builds the facts PlaybackKit needs from the user's listening history, and the listener
/// archetype the server works out.
///
/// The experience computes everything derived (top shows, best month, comparison) itself, so
/// this only supplies facts.
enum Playback2026Payload {
    static func make(year: Int, archetype: Playback2026Archetype?, dataManager: DataManager = .shared) -> PlaybackPayload {
        let podcasts = dataManager.playbackPodcastStats(in: year).map { stats in
            PlaybackPayload.Podcast(
                uuid: stats.uuid,
                title: stats.title,
                author: stats.author,
                artworkUrl: ServerHelper.imageUrl(podcastUuid: stats.uuid, size: 400).absoluteString,
                playedSeconds: stats.playedSeconds,
                episodesPlayed: stats.episodesPlayed
            )
        }

        let previousYearSeconds = dataManager.yearOverYearListeningTime(in: year).totalPlayedTimeLastYear
        let started = dataManager.playbackEpisodesStartedAndCompleted(in: year)

        return PlaybackPayload(
            year: year,
            podcasts: podcasts,
            monthlySeconds: dataManager.playbackMonthlySeconds(in: year),
            previousYearSeconds: previousYearSeconds > 0 ? previousYearSeconds : nil,
            completion: started.started > 0 ? .init(started: started.started, completed: started.completed) : nil,
            archetype: archetype.map(Self.archetype)
        )
    }

    static func archetype(_ archetype: Playback2026Archetype) -> PlaybackPayload.Archetype {
        switch archetype {
        case .flaneur: .flaneur
        case .avantGardist: .avantGardist
        case .collector: .collector
        case .aficionado: .aficionado
        case .anthologist: .anthologist
        }
    }
}
