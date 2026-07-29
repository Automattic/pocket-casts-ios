import SwiftUI

struct RelatedEpisodeCard: View {
    let episode: RelatedEpisode

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder podcast artwork
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(ThemeColor.playerContrast05()))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "headphones")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(ThemeColor.playerContrast02()))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(ThemeColor.playerContrast01()))
                    .lineLimit(1)

                Text(episode.podcastName)
                    .font(.caption)
                    .foregroundStyle(Color(ThemeColor.playerContrast02()))
                    .lineLimit(1)

                Text(episode.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(ThemeColor.playerContrast02()).opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(ThemeColor.playerContrast05()).opacity(0.6))
        )
    }
}
