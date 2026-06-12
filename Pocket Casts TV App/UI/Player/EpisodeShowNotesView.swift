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
                .font(.headline)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
        .padding(80)
        .frame(width: 862, height: 960, alignment: .topLeading)
        .task {
            await loadShowNotes()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 32) {
            artwork
                .frame(width: 160, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 8) {
                if let podcastTitle = podcast?.title {
                    Text(podcastTitle)
                        .font(.caption)
                        .foregroundStyle(Color.pcTextSecondary)
                }
                Text(episode.displayableTitle())
                    .font(.body)
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
            // height, so it relies on the parent's fixed frame to know what
            // area it can render and scroll within. `maxHeight: .infinity`
            // makes it absorb whatever space the header leaves inside the
            // modal's fixed outer height.
            ShowNotesWebView(html: showNotes)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
