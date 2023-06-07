import SwiftUI
import WidgetKit

struct UpNextLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Up_Next_Lock_Screen_Widget", provider: UpNextProvider()) { entry in
                UpNextLockScreenWidgetEntryView(entry: entry)
                    .widgetContainerBackground {
                        Color.red
                    }
            }
            .configurationDisplayName(L10n.upNext)
            .description(L10n.widgetsUpNextDescription)
            .supportedFamilies([.accessoryCircular, .accessoryRectangular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct UpNextLockScreenWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            UpNextCircularWidgetView(entry: entry)

        case .accessoryRectangular:
            UpNextRectangularWidgetView(entry: entry)

        default:
            EmptyView()
        }
    }
}

extension View {
    func widgetContainerBackground<Content: View>(_ content: () -> Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.containerBackground(for: .widget) {
                content()
            }
        } else {
            return self
        }
    }
}
// MARK: - Circular View

@available(iOSApplicationExtension 16.0, *)
struct UpNextCircularWidgetView: View {
    let entry: UpNextEntry

    var numberOfEpisodeInUpNext: Int {
        entry.upNextEpisodesCount ?? 0
    }

    var widgetURL: String {
        return numberOfEpisodeInUpNext != 0 ? "pktc://upnext?source=lock_screen_widget" : "pktc://discover"
    }

    var font: Font {
        numberOfEpisodeInUpNext > 99 ? .callout : .title
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack {
                HStack(spacing: 2) {
                    Text("\(numberOfEpisodeInUpNext)")
                        .font(font)
                        .lineLimit(1)

                    Image("up-next")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .widgetURL(URL(string: widgetURL))
        .widgetContainerBackground {
            Color.red
        }
    }
}

// MARK: - Rectangle View

@available(iOSApplicationExtension 16.0, *)
struct UpNextRectangularWidgetView: View {
    let entry: UpNextEntry

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
        return nextEpisode != nil ? "pktc://upnext?source=lock_screen_widget" : "pktc://discover"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .center) {
                    Image("up-next")
                        .resizable()
                        .frame(width: 12, height: 12)

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
        }
        .widgetURL(URL(string: widgetURL))
        .widgetContainerBackground {
            Color.red
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct Previews_UpNextLockScreenWidget_Previews: PreviewProvider {
    static var previews: some View {
        UpNextLockScreenWidgetEntryView(entry: UpNextEntry(date: Date(),
                                                           isPlaying: false,
                                                           upNextEpisodesCount: 18))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewLayout(.fixed(width: 160, height: 160))
    }
}
