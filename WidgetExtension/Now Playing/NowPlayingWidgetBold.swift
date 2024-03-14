import SwiftUI
import WidgetKit

struct NowPlayingWidgetBold: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Now_Playing_Widget_Bold", provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetEntryView(entry: entry)
                .clearBackground()
                .environment(\.widgetColorScheme, widgetColorSchemeBoldNowPlaying)
        }
        .contentMarginsDisabledIfAvailable()
        .configurationDisplayName(L10n.nowPlaying)
        .description(L10n.widgetsNowPlayingDesc)
        .supportedFamilies([.systemSmall])
    }
}
