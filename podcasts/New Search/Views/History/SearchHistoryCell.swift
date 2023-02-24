import SwiftUI
import PocketCastsDataModel
import PocketCastsUtils

struct SearchHistoryCell: View {
    @EnvironmentObject var theme: Theme

    var podcast: Podcast?

    var episode: Episode?

    var searchTerm: String?

    private var subtitle: String {
        if let episode, let podcast {
            let duration = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(episode.duration))
            return "\(L10n.episode) • \(duration) • \(podcast.title ?? "")"
        } else if let podcast {
            return "Podcast • \(podcast.author ?? "")"
        }

        return ""
    }

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

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    if let podcast {
                        PodcastCover(podcastUuid: podcast.uuid)
                            .frame(width: 48, height: 48)
                            .allowsHitTesting(false)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(podcast.title ?? "")
                                .font(style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color)
                                .lineLimit(2)
                            Text(subtitle)
                                .font(size: 14, style: .subheadline, weight: .medium)
                                .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                                .lineLimit(1)
                        }
                        .allowsHitTesting(false)
                    } else if let searchTerm {
                        Image("custom_search")
                            .frame(width: 48, height: 48)
                            .foregroundColor(AppTheme.colorForStyle(.primaryText02, themeOverride: theme.activeTheme).color)
                        Text(searchTerm)
                            .font(style: .subheadline, weight: .medium)
                    }

                    Spacer()
                    Button(action: {
                        print("remove tapped")
                    }) {
                        Image("close")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(width: 48, height: 48)
                }
                ThemeableSeparatorView()
                    .frame(height: 1)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 0))
        }
    }
}
