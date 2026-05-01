import SwiftUI
import PocketCastsUtils

struct EpisodeRowButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct EpisodeRow: View {

    let episode: MockEpisode

    @Environment(\.isFocused) var isFocused: Bool

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
                    .foregroundColor(isFocused ? .textSecondaryActive : .textSecondary)
                Text(episode.title)
                    .font(.body)
                    .foregroundColor(isFocused ? .textPrimaryActive : .textPrimary)
                Text(displayDuration(for: episode.duration))
                    .font(.caption)
                    .foregroundColor(isFocused ? .textSecondaryActive : .textSecondary)
            }
            Spacer()
        }
        .padding(24)
        .background(isFocused ? Color.backgroundActive : Color.backgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: 864)
    }
}

#Preview {
    EpisodeRow(episode: MockData.makePodcasts().first!.episodes.first!)
        .environment(AppCoordinator())
        .environment(MainTabRouter())
}
