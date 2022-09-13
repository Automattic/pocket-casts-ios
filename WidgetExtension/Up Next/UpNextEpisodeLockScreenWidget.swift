import SwiftUI
import WidgetKit

struct UpNextEpisodeLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Up_Next_Episode_Lock_Screen_Widget", provider: UpNextProvider()) { entry in
                UpNextEpisodeLockScreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.upNext)
            .description(L10n.widgetsUpNextEpisodeDescription)
            .supportedFamilies([.accessoryRectangular])
        }
        else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct UpNextEpisodeLockScreenWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry

    var nextEpisode: WidgetEpisode? {
        // The first item returned is the currently playing episode
        // so we check if the queue has at least 2 episodes in it since we pull the second one in the queue
        guard let episodes = entry.episodes, episodes.count > 1 else {
            return nil
        }

        return episodes[1]
    }

    var title: String {
        nextEpisode?.episodeTitle ?? L10n.upNextEmptyTitle
    }

    var subtitle: String {
        nextEpisode?.podcastName ?? L10n.widgetsNowPlayingTapDiscover
    }

    var widgetURL: String {
        return nextEpisode != nil ? "pktc://upnext" : "pktc://discover"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center) {
                    Image("up-next")
                        .resizable()
                        .frame(width: 12.0, height: 12.0)

                    Text(L10n.upNext)
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

                Text(subtitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.secondary)
            }
        }.widgetURL(URL(string: widgetURL))
    }
}
