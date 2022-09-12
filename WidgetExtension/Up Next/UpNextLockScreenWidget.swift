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
        }
        else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct UpNextLockScreenWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry

    var numberOfEpisodeInUpNext: Int {
        (entry.episodes?.count ?? 1) - 1
    }

    var body: some View {
        ZStack {
            Color.black

            VStack {
                HStack(spacing: 2) {
                    Text("\(numberOfEpisodeInUpNext)")
                        .font(.title)

                    Image("up-next")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .widgetURL(URL(string: "pktc://last_opened"))
    }
}

@available(iOSApplicationExtension 16.0, *)
struct Previews_UpNextLockScreenWidget_Previews: PreviewProvider {
    static var previews: some View {
        UpNextLockScreenWidgetEntryView(entry: UpNextEntry(date: Date(), isPlaying: false))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
