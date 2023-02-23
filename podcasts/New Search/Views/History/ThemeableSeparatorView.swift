import SwiftUI

struct ThemeableSeparatorView: View {
    @EnvironmentObject var theme: Theme

    var body: some View {
        Rectangle()
            .foregroundColor(AppTheme.tableDividerColor(for: theme.activeTheme).color)
            .frame(height: 0.5)
    }
}
