import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

    private var episode: Episode {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        return episode
    }

    init() {
        UITableViewHeaderFooterView.appearance().backgroundView = UIView()
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                .frame(height: 0.5)

            List {
                HStack {
                    Text(L10n.searchRecent)
                        .font(style: .title2, weight: .bold)
                    Spacer()
                    Button(L10n.historyClearAll.uppercased()) {}
                        .font(style: .footnote, weight: .bold)
                        .buttonStyle(PrimaryButtonStyle())
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 12))
                .listSectionSeparator(.hidden)
                .listRowSeparator(.hidden)
                .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)

                Section {
                    SearchHistoryPodcastCell(podcast: Podcast.previewPodcast())
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchHistoryPodcastCell(searchTerm: "Search term")
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)

                    SearchHistoryPodcastCell(podcast: Podcast.previewPodcast(), episode: episode)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }
            }
        }
        .background(AppTheme.colorForStyle(.primaryUi04, themeOverride: theme.activeTheme).color)
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryPodcastCell: View {
    @EnvironmentObject var theme: Theme

    var podcast: Podcast?

    var episode: Episode?

    var searchTerm: String?

    private var subtitle: String {
        if let episode, let podcast {
            let duration = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration))
            return "Episode • \(duration) • \(podcast.title ?? "")"
        } else if let podcast {
            return "Podcast • \(podcast.author ?? "")"
        }

        return ""
    }

    var body: some View {
        ZStack {
            Button(action: {
                print("row tapped")
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    if let podcast {
                        PodcastCover(podcastUuid: podcast.uuid)
                            .frame(width: 48, height: 48)
                            .allowsHitTesting(false)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(podcast.title ?? "")
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color)
                                .lineLimit(2)
                            Text(subtitle)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                                .lineLimit(1)
                        }
                        .allowsHitTesting(false)
                    } else if let searchTerm {
                        Image("custom_search")
                            .frame(width: 48, height: 48)
                        Text(searchTerm)
                            .font(style: .subheadline, weight: .medium)
                    }

                    Spacer()
                    Button(action: {
                        print("remove tapped")
                    }) {
                        Image("close")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 48, height: 48)
                }
                Rectangle()
                    .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .frame(height: 0.5)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
        }
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
            .previewWithAllThemes()
    }
}
