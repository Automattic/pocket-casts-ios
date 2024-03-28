import SwiftUI
import WidgetKit

struct NowPlayingWidgetBold: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Now_Playing_Widget_Bold", provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetEntryView(entry: entry, widgetColorSchemeLight: widgetColorSchemeBoldNowPlaying, widgetColorSchemeDark: widgetColorSchemeBoldNowPlaying)
                .clearBackground()
        }
        .contentMarginsDisabledIfAvailable()
        .configurationDisplayName(L10n.nowPlaying)
        .description(L10n.widgetsNowPlayingDesc)
        .supportedFamilies([.systemSmall])
    }
}
