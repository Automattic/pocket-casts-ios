import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UpNextEntry {
        UpNextEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> UpNextEntry {
        UpNextEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<UpNextEntry> {
        Timeline(entries: [UpNextEntry(date: Date(), configuration: configuration)], policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Up Next")]
    }
}

struct UpNextEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent

    var episodeTitle: String? {
        UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId)?.string(forKey: "upNextEpisodeTitle")
    }

    var podcastTitle: String? {
        UserDefaults(suiteName: SharedConstants.GroupUserDefaults.groupContainerId)?.string(forKey: "upNextPodcastTitle")
    }
}

struct WatchWidgetEntryView: View {
    let entry: Provider.Entry

    var title: String {
        entry.episodeTitle ?? L10n.upNextEmptyTitle
    }

    var subtitle: String {
        entry.podcastTitle ?? L10n.widgetsNowPlayingTapDiscover
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
    }
}

@main
struct WatchWidget: Widget {
    let kind: String = "WatchWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WatchWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
