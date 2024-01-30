import SwiftUI
import WidgetKit

struct AppIconWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "App_Icon_Widget", provider: StaticWidgetProvider()) { entry in
                AppIconWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.widgetsAppIconName)
            .description(L10n.widgetsAppIconDescription)
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
                .clipShape(Circle())
            Image("logo-transparent-medium")
                .resizable()
                .frame(width: 55, height: 55)
        }
        .widgetURL(URL(string: "pktc://last_opened"))
        .clearBackground()
    }
}

@available(iOSApplicationExtension 17.0, *)
struct Previews_AppIconWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconWidgetEntryView(entry: StaticEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
