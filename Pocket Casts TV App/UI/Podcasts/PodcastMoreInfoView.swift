import SwiftUI

struct PodcastMoreInfoView: View {

    let podcast: MockPodcast
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            HStack(alignment: .top, spacing: 40) {
                Image(podcast.image)
                    .resizable()
                    .frame(width: 240, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    Text(podcast.author ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(podcast.title)
                        .font(.title2)
                        .foregroundStyle(Color.textPrimary)
                }
            }

            if let description = podcast.podcastDescription {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.tvPodcastDetailAbout)
                        .font(.title3)
                        .foregroundStyle(Color.textPrimary)
                    Text(description)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 24) {
                if let network = podcast.network {
                    infoRow(label: L10n.tvPodcastDetailNetwork, value: network)
                }
                if let website = podcast.website {
                    infoRow(label: L10n.tvPodcastDetailWebsite, value: website)
                }
                if let frequency = podcast.frequency {
                    infoRow(label: L10n.tvPodcastDetailSchedule, value: frequency)
                }
                if let nextEpisode = podcast.nextEpisodeDate {
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
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
        }
    }
}

#Preview {
    PodcastMoreInfoView(podcast: MockData.makePodcasts().first!)
}
