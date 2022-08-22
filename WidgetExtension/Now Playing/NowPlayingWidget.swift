import SwiftUI
import WidgetKit

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Now_Playing_Widget", provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L10n.Localizable.nowPlaying)
        .description(L10n.Localizable.widgetsNowPlayingDesc)
        .supportedFamilies([.systemSmall])
    }
}
