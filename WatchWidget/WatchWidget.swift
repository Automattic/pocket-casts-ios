//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Leandro Alonso on 20/09/23.
//  Copyright © 2023 Shifty Jelly. All rights reserved.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Example Widget")]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct WatchWidgetEntryView: View {
    let entry: Provider.Entry

    var nextEpisode: WidgetEpisode? {
        return nil
//        // The first item returned is the currently playing episode
//        // so we check if the queue has at least 2 episodes in it since we pull the second one in the queue
//        guard let episodes = entry.episodes, episodes.count > 1 else {
//            return nil
//        }
//
//        return episodes[1]
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

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .accessoryRectangular) {
    WatchWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}    
