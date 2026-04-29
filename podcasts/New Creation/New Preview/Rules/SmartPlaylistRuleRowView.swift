import SwiftUI

struct SmartPlaylistRuleRowView: View {
    @EnvironmentObject var theme: Theme

    let rule: SmartPlaylistRule
    let description: String?
    let hideDivider: Bool

    @ScaledMetric(relativeTo: .largeTitle) var iconSize = CGFloat(24)

    var body: some View {
        ZStack {
            if !hideDivider {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(theme.primaryUi05)
                        .frame(height: 1)
                        .padding(.leading, 56)
                }
            }

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

                if let description {
                    Text(description)
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 17, style: .body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if rule.isMenuCompatible {
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(theme.primaryIcon02)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.trailing, 8.0)
                } else {
                    Image("cs-chevron")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(theme.primaryIcon02)
                        .frame(width: iconSize, height: iconSize)
                        .padding(.trailing, 8.0)
                }
            }
            .padding(.leading, 16.0)
            .padding(.vertical, 12.0)
            .contentShape(Rectangle())
        }
    }
}
