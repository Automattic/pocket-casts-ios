import SwiftUI
import WidgetKit

struct UpNextEpisodeLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: "Up_Next_Episode_Lock_Screen_Widget", provider: UpNextProvider()) { entry in
                UpNextEpisodeLockScreenWidgetEntryView(entry: entry)
            }
            .configurationDisplayName(L10n.upNext)
            .description(L10n.widgetsUpNextEpisodeDescription)
            .supportedFamilies([.accessoryRectangular])
        }
        else {
            return EmptyWidgetConfiguration()
        }
    }
}

struct UpNextEpisodeLockScreenWidgetEntryView: View {
}
