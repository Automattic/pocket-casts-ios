import SwiftUI
import PocketCastsServer

/// The `Featured` row of video episode results, shared by the `Top Results` and
/// `Episodes` search scopes. Reuses the Discover video cell, so the cards keep their
/// on-focus preview playback.
struct SearchFeaturedEpisodesRow: View {

    let episodes: [EpisodeSearchResult]

    private enum Layout {
        static let spacing = CGFloat(56)
    }

    var body: some View {
        RowSection(title: L10n.tvSearchFeaturedSectionTitle, focusSection: SearchFocusSection.featured) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Layout.spacing) {
                    ForEach(episodes, id: \.uuid) { episode in
                        DiscoverVideoEpisodeCell(episode: episode.discoverEpisode, source: DiscoverAnalytics.searchSource) {
                            SearchAnalytics.episodeTapped(episode)
                        }
                        // The cell scales up on focus, so leave room for it to grow.
                        .padding(.vertical, Layout.spacing / 2)
                        .setFocus(section: SearchFocusSection.featured)
                    }
                }
                .focusSection()
            }
            // Otherwise the focused-card drop shadow gets clipped at the
            // scroll-view boundary instead of pooling below the card.
            .scrollClipDisabled()
        }
    }
}

extension EpisodeSearchResult {
    /// Search results reshaped into what the Discover cells render, so the search rows
    /// reuse `DiscoverEpisodeCell` and `DiscoverVideoEpisodeCell` as-is. `url` carries
    /// the video stream those cells preview on focus.
    var discoverEpisode: DiscoverEpisode {
        DiscoverEpisode(uuid: uuid,
                        title: title,
                        duration: duration.map { Int($0) },
                        url: videoURL?.absoluteString,
                        podcastUuid: podcastUuid,
                        podcastTitle: podcastTitle,
                        published: publishedDate)
    }
}
