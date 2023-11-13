import Foundation
import SwiftUI

struct HungryForMoreView: View {
    var body: some View {
        Link(destination: URL(string: "pktc://discover")!) {
            HStack {
                Image("search").resizable()
                    .frame(width: 40, height: 40, alignment: .center)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.widgetsDiscoverPromptTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                    Text(L10n.widgetsDiscoverPromptMsg)
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.8))
                        .lineLimit(1)
                }
            }.offset(x: -8, y: 0)
        }
    }
}

struct HungryForMoreLargeView: View {
    var body: some View {
        Link(destination: URL(string: "pktc://discover")!) {
            VStack(alignment: .center, spacing: 16) {
                Image("search")
                    .resizable()
                    .frame(width: 60, height: 60, alignment: .center)

                VStack(spacing: 4) {
                    Text(L10n.widgetsDiscoverPromptTitle)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                    Text(L10n.widgetsDiscoverPromptMsg)
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .lineLimit(1)
                }
            }
        }
    }
}
