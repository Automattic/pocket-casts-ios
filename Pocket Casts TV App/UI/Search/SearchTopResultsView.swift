import SwiftUI
import PocketCastsServer

fileprivate enum Layout {
    static let maxItemsPerRow = 10
    static let podcastSpacing = CGFloat(48)
    static let podcastPadding = CGFloat(24)
    static let episodeSpacing = CGFloat(56)
    static let episodeCellWidth = CGFloat(864)
}

/// The default search scope: a Home-style stack of rows that blends the video,
/// episode and podcast results into a single screen. Each row is a preview —
/// the dedicated `Podcasts` and `Episodes` scopes hold the full lists.
struct SearchTopResultsView<ViewModel: SearchableViewModel>: View {

    let model: ViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: RowSectionLayout.sectionSpacing) {
                featuredRow
                episodesRow
                podcastsRow
            }
        }
    }

    @ViewBuilder
    private var featuredRow: some View {
        let episodes = Array(model.videoEpisodeResults.prefix(Layout.maxItemsPerRow))
        if !episodes.isEmpty {
            SearchFeaturedEpisodesRow(episodes: episodes)
        }
    }

    @ViewBuilder
    private var episodesRow: some View {
        let episodes = Array(model.remainingEpisodeResults.prefix(Layout.maxItemsPerRow))
        if !episodes.isEmpty {
            RowSection(title: L10n.episodes, focusSection: SearchFocusSection.episodes) {
                horizontalRow(spacing: Layout.episodeSpacing) {
                    ForEach(episodes, id: \.uuid) { episode in
                        DiscoverEpisodeCell(episode: episode.discoverEpisode, source: DiscoverAnalytics.searchSource) {
                            SearchAnalytics.episodeTapped(episode)
                        }
                        .frame(width: Layout.episodeCellWidth)
                        .setFocus(section: SearchFocusSection.episodes)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var podcastsRow: some View {
        let podcasts = Array(model.podcastOnlyResults.prefix(Layout.maxItemsPerRow))
        if !podcasts.isEmpty {
            RowSection(title: L10n.podcastsPlural, focusSection: SearchFocusSection.podcasts) {
                horizontalRow(spacing: Layout.podcastSpacing) {
                    ForEach(podcasts, id: \.uuid) { podcast in
                        NavigationLink(value: podcast) {
                            PodcastCoverCard(uuid: podcast.uuid)
                        }
                        .buttonStyle(.card)
                        .padding(.vertical, Layout.podcastPadding)
                        .setFocus(section: SearchFocusSection.podcasts)
                        .simultaneousGesture(TapGesture().onEnded {
                            SearchAnalytics.podcastTapped(podcast)
                        })
                    }
                }
            }
        }
    }

    private func horizontalRow<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing, content: content)
                .focusSection()
        }
        // Otherwise the focused-card drop shadow gets clipped at the
        // scroll-view boundary instead of pooling below the card.
        .scrollClipDisabled()
    }
}
