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
        entry.episode?.episodeTitle ?? L10n.widgetsNothingPlaying
    }

    var subtitle: String {
        if let playingEpisode = entry.episode {
            return entry.isPlaying ? L10n.nowPlaying : L10n.podcastTimeLeft(CommonWidgetHelper.durationString(duration: playingEpisode.duration))
        } else {
            return L10n.widgetsNowPlayingTapDiscover
        }
    }

    var widgetURL: String {
        return entry.episode != nil ? "pktc://last_opened" : "pktc://discover"
    }

    var body: some View {
        HStack {
            Image("logo-transparent")

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                    .lineLimit(2)
                    .layoutPriority(1)

                Text(subtitle.localizedUppercase)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.secondary)
                    .layoutPriority(1)
            }
        }.widgetURL(URL(string: widgetURL))
    }
}
