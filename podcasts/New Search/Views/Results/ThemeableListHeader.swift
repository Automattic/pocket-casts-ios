import SwiftUI

struct ThemeableListHeader: View {
    @EnvironmentObject var theme: Theme

    let title: String

    let actionTitle: String

    var body: some View {
        HStack {
            Text(title)
                .font(style: .title2, weight: .bold)
            Spacer()
            Button(actionTitle.uppercased()) {}
                .font(style: .footnote, weight: .bold)
                .buttonStyle(PrimaryButtonStyle())
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 12))
        .listSectionSeparator(.hidden)
        .listRowSeparator(.hidden)
        .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
    }
}
