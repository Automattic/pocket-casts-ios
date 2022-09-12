import SwiftUI
import WidgetKit

struct UpNextLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Up_Next_Lock_Screen_Widget", provider: UpNextProvider()) { entry in
                UpNextLockScreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.upNext)
            .description("See the number of podcasts on your Up Next queue.")
            .supportedFamilies([.accessoryCircular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct UpNextLockScreenWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            Text("\(entry.episodes?.count ?? 0)")
                .font(.title)
            Text("Up Next".uppercased())
                .font(.footnote)
            Image("logo-transparent")
                .resizable()
                .frame(width: 12, height: 12)
        }
        .widgetURL(URL(string: "pktc://last_opened"))
    }
}
