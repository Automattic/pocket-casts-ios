import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel

    let episode: EpisodeSearchResult?
    let result: PodcastFolderSearchResult?
    let played: Bool

    init(episode: EpisodeSearchResult?, result: PodcastFolderSearchResult?, played: Bool = false) {
        self.episode = episode
        self.result = result
        self.played = episode != nil && played
    }

    var body: some View {
        ZStack {
            Button(action: {
                if let episode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid, NavigationManager.podcastKey: episode.podcastUuid])
                    searchHistory.add(episode: episode)
                    searchAnalyticsHelper.trackResultTapped(episode)
                } else if let result {
                    result.navigateTo()
                    searchHistory.add(podcast: result)
                    searchAnalyticsHelper.trackResultTapped(result)
                }
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    (episode?.podcastUuid ?? result?.uuid).map {
                        SearchEntryImage(uuid: $0, kind: result?.kind)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let episode {
                            Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase)
                                .font(style: .footnote, weight: .bold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            Text(episode.title)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration ?? 0)))
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        } else if let result {
                            Text(result.titleToDisplay)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(result.kind == .folder ? L10n.folder : result.authorToDisplay)
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        }
                    }
                    .allowsHitTesting(false)

                    if episode != nil, played {
                        Spacer()
                        Image("list_played", bundle: nil)
                            .renderingMode(.template)
                            .foregroundStyle(AppTheme.episodeCellPlayedIndicatorColor().color)
                    }

                    if let result, result.kind == .podcast {
                        Spacer()
                        SubscribeButtonView(podcastUuid: result.uuid, source: searchAnalyticsHelper.source)
                    }
                }
                .padding(.trailing, 8)
                .opacity(played ? 0.5 : 1.0)
                ThemedDivider()
            }
            .padding(EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 0))
        }
    }
}

extension PodcastFolderSearchResult {
    var titleToDisplay: String {
        title ?? ""
    }

    var authorToDisplay: String {
        author ?? ""
    }
}
