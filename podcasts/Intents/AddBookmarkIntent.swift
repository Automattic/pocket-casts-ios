import AppIntents
import PocketCastsDataModel
import PocketCastsUtils
import SwiftUI

@available(iOS 16.0, *)
enum AddBookmarkError: Error, CustomLocalizedStringResourceConvertible {
    case episodeNotFound
    case bookmarksNotUnlocked
    case invalidTimestamp
    case addBookmarkFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .episodeNotFound:
            "Episode not found"
        case .bookmarksNotUnlocked:
            "Bookmarks feature not unlocked"
        case .invalidTimestamp:
            "Invalid timestamp provided"
        case .addBookmarkFailed:
            "Failed to add bookmark"
        }
    }
}

@available(iOS 16.0, *)
struct AddBookmarkIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Bookmark"
    static var description = IntentDescription("Add a bookmark to the current episode or at a specific timestamp")

    @Parameter(title: "Episode")
    var episode: EpisodeSearchEntity?
    
    @Parameter(title: "Timestamp (seconds)", description: "Optional timestamp to bookmark (uses current time if not provided)")
    var timestamp: Double?
    
    @Parameter(title: "Title", description: "Optional title for the bookmark")
    var title: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add bookmark to \(\.$episode)") {
            \.$timestamp
            \.$title
        }
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView & ReturnsValue<String> {
        #if APPCLIP
        throw AddBookmarkError.bookmarksNotUnlocked
        #else

        guard PaidFeature.bookmarks.isUnlocked else {
            throw AddBookmarkError.bookmarksNotUnlocked
        }

        let targetEpisode: BaseEpisode
        let bookmarkTime: TimeInterval

        if let episode = episode {
            // Find the specific episode
            guard let dbEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episode.episodeUuid) else {
                throw AddBookmarkError.episodeNotFound
            }
            targetEpisode = dbEpisode

            // Use provided timestamp or current playback time
            if let timestamp = timestamp {
                guard timestamp >= 0 else {
                    throw AddBookmarkError.invalidTimestamp
                }
                bookmarkTime = timestamp
            } else {
                // Use current playback time if this episode is playing
                if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.episodeUuid) {
                    bookmarkTime = PlaybackManager.shared.currentTime()
                } else {
                    bookmarkTime = 0
                }
            }
        } else {
            // Use currently playing episode
            guard let currentEpisode = PlaybackManager.shared.currentEpisode() else {
                throw AddBookmarkError.episodeNotFound
            }
            targetEpisode = currentEpisode
            
            // Use provided timestamp or current playback time
            if let timestamp = timestamp {
                guard timestamp >= 0 else {
                    throw AddBookmarkError.invalidTimestamp
                }
                bookmarkTime = timestamp
            } else {
                bookmarkTime = PlaybackManager.shared.currentTime()
            }
        }

        let bookmarkTitle = title ?? L10n.bookmarkDefaultTitle
        let timeString = TimeFormatter.shared.multipleUnitFormattedShortTime(time: bookmarkTime)
        
        // Request confirmation with detailed context
        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog(stringLiteral: "Add bookmark '\(bookmarkTitle)' at \(timeString) in '\(targetEpisode.displayableTitle())'?")
            )
        )

        // Add the bookmark
        guard let bookmark = PlaybackManager.shared.bookmarkManager.add(
            to: targetEpisode,
            at: bookmarkTime,
            title: bookmarkTitle
        ) else {
            throw AddBookmarkError.addBookmarkFailed
        }

        // Track analytics
        Analytics.track(.bookmarkCreated, source: BookmarkAnalyticsSource.appIntent, properties: [
            "episode_uuid": targetEpisode.uuid,
            "podcast_uuid": (targetEpisode as? Episode)?.podcastUuid ?? "user_file",
            "time": Int(bookmarkTime)
        ])

        return .result(
            value: "Bookmark added at \(timeString)",
            view: AddBookmarkSnippetView(
                episodeTitle: targetEpisode.displayableTitle(),
                bookmarkTime: timeString,
                bookmarkTitle: bookmarkTitle
            )
        )
        #endif
    }
}

@available(iOS 16.0, *)
struct AddBookmarkSnippetView: View {
    let episodeTitle: String
    let bookmarkTime: String
    let bookmarkTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bookmark Added", systemImage: "bookmark.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.green)
                    Text(bookmarkTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.orange)
                    Text(bookmarkTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(.blue)
                    Text(episodeTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
