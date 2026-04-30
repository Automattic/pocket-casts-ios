import SwiftUI

struct SmartPlaylistRuleRowView<ContentView: View>: View {
    @EnvironmentObject var theme: Theme

    let rule: SmartPlaylistRule
    @ViewBuilder let trailing: () -> ContentView

    @ScaledMetric(relativeTo: .largeTitle) var iconSize = CGFloat(24)

    var body: some View {
        HStack(alignment: .center) {
            Image(rule.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.primaryIcon03)
                .frame(width: iconSize, height: iconSize)
                .padding(.trailing, 8.0)

            Text(rule.title)
                .foregroundStyle(theme.primaryText01)
                .font(size: 17, style: .body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()

            trailing()
        }
        .padding(.leading, 16.0)
        .padding(.vertical, 12.0)
        .contentShape(Rectangle())
    }
}
