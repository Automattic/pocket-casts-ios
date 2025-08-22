import SwiftUI

struct SmartPlaylistRuleRowView: View {
    @EnvironmentObject var theme: Theme

    let rule: SmartPlaylistRule
    let description: String?
    let hideDivider: Bool
    let action: (SmartPlaylistRule) -> Void

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
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8.0)

                Text(rule.title)
                    .foregroundStyle(theme.primaryText01)
                    .font(size: 17, style: .body)
                    .lineLimit(1)

                Spacer()

                if let description {
                    Text(description)
                        .foregroundStyle(theme.primaryText02)
                        .font(size: 17, style: .body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Image("cs-chevron")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryIcon02)
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8.0)
            }
            .padding(.leading, 16.0)
            .frame(height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                action(rule)
            }
        }
    }
}
