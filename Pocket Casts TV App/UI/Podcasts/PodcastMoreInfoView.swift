import SwiftUI
import PocketCastsDataModel

struct PodcastMoreInfoView: View {

    let podcast: Podcast
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            HStack(alignment: .top, spacing: 40) {
                PodcastImage(uuid: podcast.uuid, size: .page)
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    Text(podcast.author ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.pcTextSecondary)
                    Text(podcast.title ?? "")
                        .font(.title2)
                        .foregroundStyle(Color.pcTextPrimary)
                }
            }

            if let description = podcast.podcastDescription {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.tvPodcastDetailAbout)
                        .font(.title3)
                        .foregroundStyle(Color.pcTextPrimary)
                    Text(description)
                        .font(.body)
                        .foregroundStyle(Color.pcTextSecondary)
                }
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
        .padding(80)
        .frame(width: 862, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
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
}

#Preview {
    PodcastMoreInfoView(podcast: MockData.makeStubPodcasts().first!)
}
