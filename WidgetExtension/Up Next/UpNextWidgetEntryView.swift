import Foundation
import SwiftUI

struct UpNextWidgetEntryView: View {
    @State var entry: UpNextProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.widgetColorScheme) var colorScheme

    var body: some View {
        if let episodes = entry.episodes, episodes.count > 0 {
            if family == .systemMedium {
                UpNextMediumWidgetView(episodes: episodes, filterName: entry.filterName, isPlaying: entry.isPlaying)
            } else {
                UpNextLargeWidgetView(episodes: episodes, filterName: entry.filterName, isPlaying: entry.isPlaying)
            }
        } else {
            VStack(alignment: .center) {
                HStack(alignment: .top) {
                    Text(L10n.widgetsNothingPlaying)
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image("logo_red_small")
                        .frame(width: 28, height: 28, alignment: .topTrailing)
                        .accessibility(hidden: true)
                }
                .padding(.init(top: 16, leading: 16, bottom: 0, trailing: 16))

                Spacer()
                if family == .systemMedium {
                    HungryForMoreView()
                        .offset(x: 0, y: -4)
                } else {
                    HungryForMoreLargeView()
                        .offset(x: 0, y: -8)
                }
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(darkBackgroundColor) // TODO: what should this be?
        }
    }
}
