import SwiftUI

struct SearchHistoryView: View {
    @EnvironmentObject var theme: Theme

    init() {
        UITableViewHeaderFooterView.appearance().backgroundView = UIView()
    }

    var body: some View {
        List {
            Section {
                Text("A Search Item")
                    .listSectionSeparator(.hidden)
                    .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
                Text("A Second Search Item")
                    .listSectionSeparator(.hidden)
                    .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
                Text("A Third Search Item")
                    .listRowSeparatorTint(AppTheme.tableDividerColor(for: theme.activeTheme).color)
                    .listRowBackground(AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color)
            } header: {
                HStack {
                    Text("Recent searches")
                        .font(style: .title3, weight: .bold)
                    Spacer()
                    Button("Clear all".uppercased()) {}
                        .font(style: .footnote, weight: .bold)
                        .foregroundColor(AppTheme.colorForStyle(.primaryInteractive01, themeOverride: theme.activeTheme).color)
                }
                .environment(\.defaultMinListHeaderHeight, 1)
                .listRowInsets(EdgeInsets(top: -30, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .background(AppTheme.colorForStyle(.primaryUi04, themeOverride: theme.activeTheme).color)
        .listStyle(.plain)
        .applyDefaultThemeOptions()
    }
}

struct SearchHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        SearchHistoryView()
            .environmentObject(Theme(previewTheme: .rosé))
    }
}
