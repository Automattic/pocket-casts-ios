import Foundation
import SwiftUI

struct HungryForMoreView: View {
    let colorScheme: PCWidgetColorScheme

    var body: some View {
        Link(destination: URL(string: "pktc://discover")!) {
            VStack(alignment: .center, spacing: 3) {
                Text(L10n.widgetsDiscoverPromptTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme.bottomTextColor)
                    .lineLimit(1)
                Text(L10n.widgetsDiscoverPromptMsg)
                    .font(.caption2)
                    .foregroundColor(colorScheme.bottomTextColor.opacity(0.8))
                    .lineLimit(1)
            }.offset(x: -8, y: 0)
        }
    }
}

struct HungryForMoreLargeView: View {
    let colorScheme: PCWidgetColorScheme

    var body: some View {
        Link(destination: URL(string: "pktc://discover")!) {
            VStack(alignment: .center, spacing: 4) {
                Text(L10n.widgetsDiscoverPromptTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme.bottomTextColor)
                    .lineLimit(1)
                Text(L10n.widgetsDiscoverPromptMsg)
                    .font(.caption2)
                    .foregroundColor(colorScheme.bottomTextColor.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }
}
