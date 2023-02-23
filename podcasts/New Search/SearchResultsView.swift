import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchResultsView: View {
    @EnvironmentObject var theme: Theme

    private var episode: Episode {
        let episode = Episode()
        episode.title = "Episode title"
        episode.duration = 3600
        episode.publishedDate = Date()
        return episode
    }

    var body: some View {
        List {
            HStack {
                Text(L10n.podcastsPlural)
                    .font(style: .title2, weight: .bold)
                Spacer()
                Button(L10n.discoverShowAll.uppercased()) {}
                    .font(style: .footnote, weight: .bold)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 12))
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
            .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)

            Section {
                ScrollView {
                    LazyHStack {
                        PodcastsPageView()
                    }
                }
            }

            HStack {
                Text("Episodes")
                    .font(style: .title2, weight: .bold)
                Spacer()
                Button(L10n.discoverShowAll.uppercased()) {}
                    .font(style: .footnote, weight: .bold)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 12))
            .listSectionSeparator(.hidden)
            .listRowSeparator(.hidden)
            .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)

            Section {
                SearchResultsEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)

                SearchResultsEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)

                SearchResultsEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)

                SearchResultsEpisodeCell(podcast: Podcast.previewPodcast(), episode: episode)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchResultsEpisodeCell: View {
    @EnvironmentObject var theme: Theme

    var podcast: Podcast

    var episode: Episode

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

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: 48, height: 48)
                        .allowsHitTesting(false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase)
                            .font(style: .footnote, weight: .bold)
                            .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                        Text(podcast.title ?? "")
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color)
                            .lineLimit(2)
                        Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration)))
                            .font(style: .caption, weight: .semibold)
                            .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                            .lineLimit(1)
                    }
                    .allowsHitTesting(false)
                }
                .padding(.trailing, 16)
                Rectangle()
                    .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .frame(height: 0.5)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
        }
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView()
            .previewWithAllThemes()
    }
}

struct PodcastsPageView: View {
    @EnvironmentObject var theme: Theme

    let size: Double = 0.48
    var body: some View {
        TabView {
            ForEach(0..<30) { i in
                GeometryReader { geometry in
                    HStack(spacing: 10) {
                        PodcastResultCell(podcast: Podcast.previewPodcast())

                        PodcastResultCell(podcast: Podcast.previewPodcast())
                    }
                }
            }
            .padding(.all, 10)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.3)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

struct PodcastResultCell: View {
    @EnvironmentObject var theme: Theme

    let podcast: Podcast

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    print("podcast tapped")
                }) {
                    PodcastCover(podcastUuid: podcast.uuid)
                }
                Button(action: {
                    print("subscribe")
                }) {
                    Image("discover_subscribe_dark")
                }
                .background(ThemeColor.veil().color)
                .foregroundColor(ThemeColor.contrast01().color)
                .cornerRadius(30)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 6))
            }

            Button(action: {
                print("podcast tapped")
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Podcast.previewPodcast().title ?? "")
                        .lineLimit(1)
                        .font(style: .subheadline, weight: .medium)
                    Text(Podcast.previewPodcast().author ?? "")
                        .lineLimit(1)
                        .font(size: 14, style: .subheadline, weight: .medium)
                        .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                }
            }
        }
    }
}
