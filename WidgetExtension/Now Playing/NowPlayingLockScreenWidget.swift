import SwiftUI
import WidgetKit

struct NowPlayingLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Now_Playing_Lock_Screen_Widget", provider: NowPlayingProvider()) { entry in
                NowPlayingLockscreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.nowPlaying)
            .description(L10n.widgetsNowPlayingDesc)
            .supportedFamilies([.accessoryRectangular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct NowPlayingLockscreenWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    var title: String {
        entry.episode?.episodeTitle ?? L10n.widgetsNowPlayingTapDiscover
    }

    var subtitle: String {
        if let playingEpisode = entry.episode {
            return entry.isPlaying ? L10n.nowPlaying : L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration))
        } else {
            return L10n.widgetsNothingPlaying
        }
    }

    var widgetURL: String {
        return entry.episode != nil ? "pktc://show_player" : "pktc://discover"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image("logo-transparent")
                        .resizable()
                        .frame(width: 16.0, height: 16.0)

                    Text(subtitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primary)
                        .layoutPriority(1)
                }

                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)
                    .layoutPriority(1)
                    .lineLimit(2)

                // Hide the podcast name if it's not available
                if let name = entry.episode?.podcastName {
                    Text(name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .widgetURL(URL(string: widgetURL))
        .clearBackground()
    }
}
