import AppIntents
import PocketCastsDataModel
import Foundation

enum GetListeningHistoryError: Error, CustomLocalizedStringResourceConvertible {
    case invalidDateRange
    case noEpisodes

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidDateRange:
            "Invalid date range provided"
        case .noEpisodes:
            "No episodes found in listening history"
        }
    }
}

struct GetListeningHistoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Listening History"
    static var description = IntentDescription("Get recently listened to episodes within a date range")

    @Parameter(title: "Start Date", description: "Start date for listening history (optional)")
    var startDate: Date?

    @Parameter(title: "End Date", description: "End date for listening history (optional)")
    var endDate: Date?

    @Parameter(title: "Limit", description: "Maximum number of episodes to return", default: 50)
    var limit: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Get last \(\.$limit) episodes from listening history") {
            \.$startDate
            \.$endDate
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[EpisodeSearchEntity]> {
        // Validate date range if both dates are provided
        if let start = startDate, let end = endDate {
            guard start <= end else {
                throw GetListeningHistoryError.invalidDateRange
            }
        }

        let episodes: [Episode]

        if let start = startDate, let end = endDate {
            // Use custom date range query
            let startTimestamp = Int64(start.timeIntervalSince1970)
            let endTimestamp = Int64(end.timeIntervalSince1970)

            let customWhere = """
                lastPlaybackInteractionDate IS NOT NULL
                AND lastPlaybackInteractionDate > 0
                AND lastPlaybackInteractionDate BETWEEN \(startTimestamp) AND \(endTimestamp)
                ORDER BY lastPlaybackInteractionDate DESC
                LIMIT \(limit)
            """

            episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: customWhere, arguments: nil)
        } else if let start = startDate {
            // Episodes since start date
            let startTimestamp = Int64(start.timeIntervalSince1970)

            let customWhere = """
                lastPlaybackInteractionDate IS NOT NULL
                AND lastPlaybackInteractionDate > 0
                AND lastPlaybackInteractionDate >= \(startTimestamp)
                ORDER BY lastPlaybackInteractionDate DESC
                LIMIT \(limit)
            """

            episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: customWhere, arguments: nil)
        } else if let end = endDate {
            // Episodes before end date
            let endTimestamp = Int64(end.timeIntervalSince1970)

            let customWhere = """
                lastPlaybackInteractionDate IS NOT NULL
                AND lastPlaybackInteractionDate > 0
                AND lastPlaybackInteractionDate <= \(endTimestamp)
                ORDER BY lastPlaybackInteractionDate DESC
                LIMIT \(limit)
            """

            episodes = DataManager.sharedManager.findEpisodesWhere(customWhere: customWhere, arguments: nil)
        } else {
            // No date range specified, get recent episodes
            episodes = DataManager.sharedManager.episodesWithListenHistory(limit: limit)
        }

        guard !episodes.isEmpty else {
            throw GetListeningHistoryError.noEpisodes
        }

        // Convert to EpisodeSearchEntity
        let episodeEntities = episodes.compactMap { episode -> EpisodeSearchEntity? in
            guard let podcast = episode.parentPodcast() else { return nil }
            return EpisodeSearchEntity(
                episodeUuid: episode.uuid,
                title: episode.title ?? "",
                podcastTitle: podcast.title ?? "",
                podcastUuid: podcast.uuid,
            )
        }

        let dateRangeText: String
        if let start = startDate, let end = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateRangeText = " between \(formatter.string(from: start)) and \(formatter.string(from: end))"
        } else if let start = startDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateRangeText = " since \(formatter.string(from: start))"
        } else if let end = endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            dateRangeText = " before \(formatter.string(from: end))"
        } else {
            dateRangeText = ""
        }

        return .result(value: episodeEntities)
    }
}
