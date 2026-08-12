import SwiftUI
import PocketCastsUtils
import PocketCastsServer

struct SearchEpisodeRow: View {

    let model: EpisodeSearchResult

    @Environment(\.isFocused) private var isFocused: Bool

    private var isHighlighted: Bool {
        isFocused
    }

    enum Layout {
        static let episodeImageSize = CGFloat(124)
    }

    @ViewBuilder
    private var thumbnail: some View {
        PodcastImage(uuid: model.podcastUuid, size: .list)
    }

    var body: some View {
        HStack(spacing: 24) {
            thumbnail
                .frame(width: Layout.episodeImageSize, height: Layout.episodeImageSize)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading) {
                Text(model.podcastTitle)
                    .font(.caption)
                    .foregroundColor(isHighlighted ? .pcTextSecondaryActive : .pcTextSecondary)
                Text(model.title)
                    .font(.body)
                    .foregroundColor(isHighlighted ? .pcTextPrimaryActive : .pcTextPrimary)
                    .lineLimit(2)
                if let duration = model.duration {
                    Text(TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(duration)))
                        .font(.caption)
                        .foregroundColor(isHighlighted ? .pcTextSecondaryActive : .pcTextSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(32)
        .background(isHighlighted ? Color.pcBackgroundActive : Color.pcBackgroundSunken)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
