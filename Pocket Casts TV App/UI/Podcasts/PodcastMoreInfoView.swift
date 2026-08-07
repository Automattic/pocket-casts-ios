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
        static let contentInsets = EdgeInsets(top: 80, leading: 80, bottom: 0, trailing: 80)
    }

    private var descriptionHTML: String {
        podcast.podcastHTMLDescription ?? podcast.podcastDescription ?? ""
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            metadataColumn
                .frame(width: Layout.metadataColumnWidth, alignment: .leading)
                .padding(.bottom, 40)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    if let author = podcast.author {
                        Text(author)
                            .font(.caption)
                            .foregroundStyle(Color.pcTextSecondary)
                    }
                    if let title = podcast.title {
                        Text(title)
                            .font(.title2)
                            .foregroundStyle(Color.pcTextPrimary)
                    }
                }
                .accessibilityElement(children: .combine)
                if !descriptionHTML.isEmpty {
                    aboutColumn
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .padding(Layout.contentInsets)
        .frame(width: Layout.modalWidth, height: Layout.modalHeight, alignment: .topLeading)
        .task { buildDescription() }
        .remotePlayPause()
    }

    private var metadataColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            PodcastImage(uuid: podcast.uuid, size: .page)
                .frame(width: Layout.artworkSize, height: Layout.artworkSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var aboutColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        .accessibilityElement(children: .combine)
    }

    private func buildDescription() {
        let html = descriptionHTML
        guard !html.isEmpty else { return }
        descriptionText = HTMLToAttributedStringConverter.attributedString(from: html)
    }
}

#if DEBUG
// Presents `PodcastMoreInfoView` over a backdrop the way `PodcastDetailView` does in the
// app (via `.sheet`), so the preview reflects the real modal presentation.
#Preview {
    @Previewable @State var isPresented = true
    let podcast: Podcast = {
        let podcast = MockData.makeStubPodcasts().first!
        podcast.podcastHTMLDescription = RichTextPreviewSamples.longDescriptionHTML
        return podcast
    }()

    Color.pcBackgroundBase
        .ignoresSafeArea()
        .sheet(isPresented: $isPresented) {
            PodcastMoreInfoView(podcast: podcast)
        }
}
#endif
