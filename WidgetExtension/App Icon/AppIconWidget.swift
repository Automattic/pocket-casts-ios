import SwiftUI
import WidgetKit

struct StaticWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticEntry {
        StaticEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StaticEntry) -> Void) {
        completion(StaticEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StaticEntry>) -> Void) {
        completion(Timeline(entries: [StaticEntry(date: Date())], policy: .never))
    }
}

struct StaticEntry: TimelineEntry {
    let date: Date
}


struct AppIconWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "App_Icon_Widget", provider: StaticWidgetProvider()) { entry in
                AppIconWidgetEntryView(entry: entry)
            }
            .configurationDisplayName("App Icon Widget")
            .description("Launch Pocket Casts")
            .supportedFamilies([.accessoryCircular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct AppIconWidgetEntryView: View {
    @State var entry: StaticWidgetProvider.Entry

    var body: some View {
        ZStack {
            Color.black
            Image("logo-transparent-medium")
                .resizable()
                .frame(width: 55, height: 55)
                .foregroundColor(.white)
        }
        .widgetURL(URL(string: "pktc://last_opened"))
    }
}
