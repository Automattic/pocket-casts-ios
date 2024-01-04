import SwiftUI
import WidgetKit

struct UpNextWidgetBold: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Up_Next_Widget_Bold", provider: UpNextProvider()) { entry in
            UpNextWidgetEntryView(entry: entry, colorScheme: widgetColorSchemeBold)
                .clearBackground()
        }
        .contentMarginsDisabledIfAvailable()
        .configurationDisplayName(L10n.upNext)
        .description("See what’s playing now, and what’s coming Up Next.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
