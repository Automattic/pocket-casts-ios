import SwiftUI
import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryCell: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var searchAnalyticsHelper: SearchAnalyticsHelper
    @EnvironmentObject var searchHistory: SearchHistoryModel
    @EnvironmentObject var searchResults: SearchResultsModel
    @EnvironmentObject var displaySearch: SearchVisibilityModel

    let entry: SearchHistoryEntry

    private var subtitle: String {
        if let episode = entry.episode {
            return "\(L10n.episode) • \(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration ?? 0))) • \(episode.podcastTitle)"
        } else if let podcast = entry.podcast {
            switch podcast.kind {
            case .folder:
                return L10n.folder
            case .podcast:
                return [L10n.podcastSingular, podcast.author].compactMap { $0 }.joined(separator: " • ")
            }
        }

        return ""
    }

    var body: some View {
        ZStack {
            Button(action: {
                if let episode = entry.episode {
                    NavigationManager.sharedManager.navigateTo(NavigationManager.episodePageKey, data: [NavigationManager.episodeUuidKey: episode.uuid, NavigationManager.podcastKey: episode.podcastUuid])
                } else if let podcast = entry.podcast {
                    podcast.navigateTo()
                } else if let searchTerm = entry.searchTerm {
                    displaySearch.isSearching = true
                    searchResults.search(term: searchTerm)
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.podcastSearchRequest, object: searchTerm)
                }
                searchAnalyticsHelper.historyItemTapped(entry)
                searchHistory.moveEntryToTop(entry)
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    if let title = entry.podcast?.title ?? entry.episode?.title,
                        let uuid = entry.podcast?.uuid ?? entry.episode?.podcastUuid {
                        SearchEntryImage(uuid: uuid, kind: entry.podcast?.kind)
                            .padding(.trailing, 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                                .lineLimit(2)
                            Text(subtitle)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                                .lineLimit(1)
                        }
                        .allowsHitTesting(false)
                    } else if let searchTerm = entry.searchTerm {
                        Image("search")
                            .frame(width: 56, height: 56)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .padding(.trailing, 12)
                        Text(searchTerm)
                            .font(style: .subheadline, weight: .medium)
                    }

                    Spacer()
                    Button(action: {
                        withAnimation {
                            searchHistory.remove(entry: entry)
                            searchAnalyticsHelper.historyItemDeleted(entry)
                        }
                    }) {
                        Image("close")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 48, height: 48)
                }
                ThemedDivider()
                    .frame(height: 1)
            }
            .padding(EdgeInsets(top: 12, leading: 8, bottom: 0, trailing: 0))
        }
    }
}

struct SearchEntryImage: View {
    let uuid: String
    let kind: PodcastFolderSearchResult.Kind?

    var body: some View {
        image
            .frame(width: 56, height: 56)
            .cornerRadius(4)
            .shadow(radius: 3, x: 0, y: 1)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var image: some View {
        if kind == .folder {
            SearchFolderPreviewWrapper(uuid: uuid)
        } else {
            PodcastImage(uuid: uuid)
        }
    }
}
