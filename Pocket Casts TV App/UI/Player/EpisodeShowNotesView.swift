import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

/// Modal that renders an episode's HTML show notes alongside a header summary
/// (artwork, episode title, podcast name, publish date).
///
/// Presentation is via `.sheet`, matching `PodcastMoreInfoView`'s pattern.
struct EpisodeShowNotesView: View {
    let episode: BaseEpisode
    let podcast: Podcast?

    @State private var showNotes: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            Text(L10n.tvEpisodeShowNotesTitle)
                .font(.title3)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
        .padding(80)
        .frame(width: 862, alignment: .topLeading)
        .task {
            await loadShowNotes()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 40) {
            artwork
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 8) {
                if let podcastTitle = podcast?.title {
                    Text(podcastTitle)
                        .font(.caption)
                        .foregroundStyle(Color.pcTextSecondary)
                }
                Text(episode.displayableTitle())
                    .font(.headline)
                    .foregroundStyle(Color.pcTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(metadataLine)
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
            }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let podcastUuid = (episode as? Episode)?.podcastUuid {
            PodcastImage(uuid: podcastUuid, size: .page)
        } else {
            Image(ImageResource.pcLogo)
                .resizable()
                .scaledToFit()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let showNotes {
            // `UITextView` with `isScrollEnabled = true` reports no intrinsic
            // height, so without an explicit frame the modal collapses to just
            // the header. The fixed height gives the text view a real frame to
            // render and scroll within.
            ShowNotesWebView(html: showNotes)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 720)
        } else {
            HStack(spacing: 16) {
                ProgressView()
                Text(L10n.tvEpisodeShowNotesLoading)
                    .font(.body)
                    .foregroundStyle(Color.pcTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var metadataLine: String {
        let date = DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase
        let duration = episode.displayableDuration
        return [date, duration].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func loadShowNotes() async {
        guard let podcastUuid = (episode as? Episode)?.podcastUuid else {
            showNotes = CacheServerHandler.noShowNotesMessage
            return
        }
        showNotes = await ShowNotesLoader.shared.loadShowNotes(
            podcastUuid: podcastUuid,
            episodeUuid: episode.uuid
        )
    }
}
