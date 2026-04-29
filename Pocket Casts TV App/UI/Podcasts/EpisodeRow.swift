import SwiftUI
import PocketCastsUtils

struct EpisodeRow: View {

    let episode: MockEpisode

    enum Layout {
        static let episodeImageSize = CGFloat(124)
    }

    func displayDate(for date: Date) -> String {
        let episodeDate = DateFormatHelper.sharedHelper.tinyLocalizedFormat(date).localizedUppercase
        return episodeDate
    }

    func displayDuration(for time: Double) -> String {
        let time = TimeFormatter.shared.multipleUnitFormattedShortTime(time: time)
        return time
    }

    var body: some View {
        HStack(spacing: 24) {
            Image(episode.image)
                .resizable()
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading) {
                Text(displayDate(for: episode.publishedDate))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(episode.title)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                Text(displayDuration(for: episode.duration))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(24)
        .background(Color.backgroundSunken)
    }
}

#Preview {
    EpisodeRow(episode: MockData.makePodcasts().first!.episodes.first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
