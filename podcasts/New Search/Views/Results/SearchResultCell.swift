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
                    if result?.kind == .podcast || episode != nil {
                        PodcastImage(uuid: episode?.podcastUuid ?? result?.uuid ?? "")
                            .frame(width: 56, height: 56)
                            .cornerRadius(4)
                            .shadow(radius: 3, x: 0, y: 1)
                            .allowsHitTesting(false)
                    } else if let result {
                        SearchFolderPreviewWrapper(uuid: result.uuid)
                            .frame(width: 56, height: 56)
                            .cornerRadius(4)
                            .shadow(radius: 3, x: 0, y: 1)
                            .allowsHitTesting(false)
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
                            Text(result.title)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(result.kind == .folder ? L10n.folder : result.author)
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        }
                    }
                    .allowsHitTesting(false)

                    if let result, result.kind == .podcast {
                        Spacer()
                        SubscribeButtonView(podcastUuid: result.uuid)
                    }
                }
                .padding(.trailing, 8)
                ThemedDivider()
            }
            .padding(EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 0))
        }
    }
}
