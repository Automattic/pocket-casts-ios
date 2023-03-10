import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct SearchEpisodeCell: View {
    @EnvironmentObject var theme: Theme

    let episode: EpisodeSearchResult?
    let podcast: PodcastSearchResult?
    let searchHistory: SearchHistoryModel?

    var body: some View {
        ZStack {
            Button(action: {
                if let episode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid, NavigationManager.podcastKey: episode.podcastUuid])
                    searchHistory?.add(episode: episode)
                } else if let podcast {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.podcastPageKey, data: [NavigationManager.podcastKey: podcast])
                    searchHistory?.add(podcast: podcast)
                }
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: episode?.podcastUuid ?? podcast?.uuid ?? "")
                        .frame(width: 48, height: 48)
                        .allowsHitTesting(false)
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
                        } else if let podcast {
                            Text(podcast.title)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(podcast.author)
                                .font(style: .caption, weight: .semibold)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        }
                    }
                    .allowsHitTesting(false)

                    if let podcast {
                        Spacer()
                        SubscribeButtonView(podcastUuid: podcast.uuid)
                    }
                }
                .padding(.trailing, episode != nil ? 16 : 8)
                ThemedDivider()
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
        }
    }
}
