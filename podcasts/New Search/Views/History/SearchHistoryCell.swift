import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryCell: View {
    @EnvironmentObject var theme: Theme

    let entry: SearchHistoryEntry
    let searchHistory: SearchHistoryModel
    let searchResults: SearchResultsModel
    let displaySearch: SearchVisibilityModel

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
                        if entry.podcast?.kind == .folder {
                            SearchFolderPreviewWrapper(uuid: uuid)
                                .modifier(NormalCoverShadow())
                                .frame(width: 48, height: 48)
                                .allowsHitTesting(false)
                                .padding(.trailing, 12)
                        } else {
                            PodcastCover(podcastUuid: uuid)
                                .frame(width: 48, height: 48)
                                .allowsHitTesting(false)
                                .padding(.trailing, 12)
                        }

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
                        Image("custom_search")
                            .frame(width: 48, height: 48)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .padding(.trailing, 12)
                        Text(searchTerm)
                            .font(style: .subheadline, weight: .medium)
                    }

                    Spacer()
                    Button(action: {
                        withAnimation {
                            searchHistory.remove(entry: entry)
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
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
        }
    }
}
