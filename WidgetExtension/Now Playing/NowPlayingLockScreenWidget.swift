import SwiftUI
import WidgetKit

struct NowPlayingLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Now_Playing_Lock_Screen_Widget", provider: NowPlayingProvider()) { entry in
                NowPlayingLockscreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.nowPlaying)
            .description(L10n.widgetsNowPlayingDesc)
            .supportedFamilies([.accessoryRectangular])
        } else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct NowPlayingLockscreenWidgetEntryView: View {
    @State var entry: NowPlayingProvider.Entry

    var body: some View {
        VStack {
            
        }
    }
}
