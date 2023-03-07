import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchEpisodeCell: View {
    @EnvironmentObject var theme: Theme

    var podcast: Podcast

    var episode: Episode

    var body: some View {
        ZStack {
            Button(action: {
                print("row tapped")
            }) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ListCellButtonStyle())

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PodcastCover(podcastUuid: podcast.uuid)
                        .frame(width: 48, height: 48)
                        .allowsHitTesting(false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DateFormatHelper.sharedHelper.tinyLocalizedFormat(episode.publishedDate).localizedUppercase)
                            .font(style: .footnote, weight: .bold)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                        Text(podcast.title ?? "")
                            .font(style: .subheadline, weight: .medium)
                            .foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
                            .lineLimit(2)
                        Text(episode.displayableDuration)
                            .font(style: .caption, weight: .semibold)
                            .foregroundColor(AppTheme.color(for: .primaryText02, theme: theme))
                            .lineLimit(1)
                    }
                    .allowsHitTesting(false)
                }
                .padding(.trailing, 16)
                ThemedDivider()
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
        }
    }
}
