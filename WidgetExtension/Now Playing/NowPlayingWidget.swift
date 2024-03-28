import SwiftUI
import WidgetKit

struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Now_Playing_Widget", provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetEntryView(entry: entry, widgetColorSchemeLight: widgetColorSchemeContrastNowPlaying, widgetColorSchemeDark: widgetColorSchemeContrastNowPlayingDark)
                .clearBackground()
        }
        .contentMarginsDisabledIfAvailable()
        .configurationDisplayName(L10n.nowPlaying)
        .description(L10n.widgetsNowPlayingDesc)
        .supportedFamilies([.systemSmall])
    }
}
