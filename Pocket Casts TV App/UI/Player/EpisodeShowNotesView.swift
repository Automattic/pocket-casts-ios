import SwiftUI
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

/// Modal `.sheet` rendering an episode's show notes below a header (artwork, title,
/// podcast name, date).
struct EpisodeShowNotesView: View {
    let episode: BaseEpisode
    let podcast: Podcast?

    @State private var attributedShowNotes: NSAttributedString?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            Text(L10n.tvEpisodeShowNotesTitle)
                .font(.headline)
                .foregroundStyle(Color.pcTextPrimary)
            content
        }
        .padding([.horizontal, .top], 80)
        .frame(width: 1200, height: 920, alignment: .topLeading)
        .task {
            Analytics.track(.episodeDetailShown)
            await loadShowNotes()
        }
        .remotePlayPause()
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
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        EpisodeArtworkView(model: EpisodeArtworkViewModel(episode: episode, showEpisodeNotesImage: Settings.loadEmbeddedImages))
    }

    @ViewBuilder
    private var content: some View {
        if let attributedShowNotes {
            // Scrolling UITextView has no intrinsic height; it fills the space the
            // header leaves inside the modal's fixed frame.
            ScrollableTextView(attributedText: attributedShowNotes)
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
        let html: String
        if let podcastUuid = (episode as? Episode)?.podcastUuid {
            html = await ShowNotesLoader.shared.loadShowNotes(
                podcastUuid: podcastUuid,
                episodeUuid: episode.uuid
            )
        } else {
            html = CacheServerHandler.noShowNotesMessage
        }
        attributedShowNotes = HTMLToAttributedStringConverter.attributedString(from: html)
    }
}
