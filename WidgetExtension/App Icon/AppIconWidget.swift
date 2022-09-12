import SwiftUI
import WidgetKit

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
        }
        .widgetURL(URL(string: "pktc://last_opened"))
    }
}
