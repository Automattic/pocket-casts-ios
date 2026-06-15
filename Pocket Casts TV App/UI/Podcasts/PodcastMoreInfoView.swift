import SwiftUI
import PocketCastsDataModel
import PocketCastsServer

struct PodcastMoreInfoView: View {

    let podcast: Podcast
    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: NSAttributedString?

    private enum Layout {
        static let modalWidth = CGFloat(1280)
        static let modalHeight = CGFloat(880)
        static let metadataColumnWidth = CGFloat(360)
        static let artworkSize = CGFloat(240)
        static let columnGutter = CGFloat(64)
    }

    private var descriptionHTML: String {
        podcast.podcastHTMLDescription ?? podcast.podcastDescription ?? ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: Layout.columnGutter) {
            metadataColumn
                .frame(width: Layout.metadataColumnWidth, alignment: .leading)
            if !descriptionHTML.isEmpty {
                aboutColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(80)
        .frame(width: Layout.modalWidth, height: Layout.modalHeight, alignment: .topLeading)
        .task { buildDescription() }
    }

    private var metadataColumn: some View {
        VStack(alignment: .leading, spacing: 40) {
            PodcastImage(uuid: podcast.uuid, size: .page)
                .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 8) {
                Text(podcast.author ?? "")
                    .font(.caption)
                    .foregroundStyle(Color.pcTextSecondary)
                Text(podcast.title ?? "")
                    .font(.title2)
                    .foregroundStyle(Color.pcTextPrimary)
            }
            VStack(alignment: .leading, spacing: 24) {
                if let network = podcast.author {
                    infoRow(label: L10n.tvPodcastDetailNetwork, value: network)
                }
                if let website = podcast.podcastUrl {
                    infoRow(label: L10n.tvPodcastDetailWebsite, value: website)
                }
                if let frequency = podcast.displayableFrequency() {
                    infoRow(label: L10n.tvPodcastDetailSchedule, value: frequency)
                }
                if let nextEpisode = podcast.displayableNextEpisodeDate() {
                    infoRow(label: L10n.tvPodcastDetailNextEpisode, value: nextEpisode)
                }
            }
        }
    }

    private var aboutColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tvPodcastDetailAbout)
                .font(.title3)
                .foregroundStyle(Color.pcTextPrimary)
            if let descriptionText {
                ScrollableTextView(attributedText: descriptionText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.pcTextSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.pcTextPrimary)
        }
    }

    private func buildDescription() {
        let html = descriptionHTML
        guard !html.isEmpty else { return }
        descriptionText = HTMLToAttributedStringConverter.attributedString(from: html)
    }
}

#if DEBUG
#Preview {
    PodcastMoreInfoView(podcast: {
        let podcast = MockData.makeStubPodcasts().first!
        podcast.podcastHTMLDescription = RichTextPreviewSamples.descriptionHTML
        return podcast
    }())
}
#endif
