import SwiftUI
import WidgetKit

struct UpNextLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Up_Next_Lock_Screen_Widget", provider: UpNextProvider()) { entry in
                UpNextLockScreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.upNext)
            .description(L10n.widgetsUpNextDescription)
            .supportedFamilies([.accessoryCircular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct UpNextLockScreenWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                Text("\(entry.episodes?.count ?? 0)")
                    .font(.title)

                Image("up-next")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .offset(x: -1, y: -3)
            }
        }
        .widgetURL(URL(string: "pktc://last_opened"))
    }
}
