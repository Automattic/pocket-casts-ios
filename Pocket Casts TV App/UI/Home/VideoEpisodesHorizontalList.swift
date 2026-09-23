import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct VideoEpisodesHorizontalList: View {

    let title: String
    let focusSection: String
    let episodes: [EpisodeRowViewModel]
    let episodeContext: EpisodeActionContext

    let onPlay: () -> Void

    enum Layout {
        static var spacing = CGFloat(56)
    }

    var body: some View {
        RowSection(title: title, focusSection: focusSection) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Layout.spacing) {
                    ForEach(episodes) { episode in
                        DiscoverVideoEpisodeCell(episode: makeDiscoverVideoEpisode(episode: episode), source: AnalyticsSource.home.rawValue)
                            .setFocus(section: focusSection)
                            .padding(.vertical, Layout.spacing / 2)
                    }
                }
            }
            // Otherwise the focused-card drop shadow gets clipped at the
            // scroll-view boundary instead of pooling below the pill.
            .scrollClipDisabled()
        }
    }

    func makeDiscoverVideoEpisode(episode: EpisodeRowViewModel) -> DiscoverEpisode {
        var episodeSeasonNumber: Int?
        var episodeNumber: Int?
        var videoUrl: String? = episode.episode.downloadUrl
        if let podcastEpisode = episode.episode as? Episode {
            episodeSeasonNumber = podcastEpisode.seasonNumber != -1 ? Int(podcastEpisode.seasonNumber) : nil
            episodeNumber = podcastEpisode.episodeNumber != -1 ? Int(podcastEpisode.episodeNumber) : nil
            if let hlsURL = podcastEpisode.hlsUrl {
                videoUrl = hlsURL
            }
        }

        let discoverEpisode = DiscoverEpisode(uuid: episode.episode.uuid, title: episode.displayTitle, duration: Int(episode.episode.duration), url: videoUrl, podcastUuid: episode.podcastUuid, podcastTitle: episode.podcast?.title, type: nil, published: episode.episode.publishedDate, season: episodeSeasonNumber, number: episodeNumber)

        return discoverEpisode
    }
}
