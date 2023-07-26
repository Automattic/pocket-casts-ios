import SwiftUI

/// Displays the empty state view for the bookmarks
struct BookmarksEmptyStateView<Style: EmptyStateViewStyle>: View {
    @ObservedObject var style: Style

    var body: some View {
        EmptyStateView(title: L10n.noBookmarksTitle, message: L10n.noBookmarksMessage, actions: [
            .init(title: L10n.noBookmarksButtonTitle, action: {

                NavigationManager.sharedManager.navigateTo(NavigationManager.settingsHeadphoneKey)

            })
        ], style: style)
    }
}

// MARK: - Styles

class DefaultEmptyStateStyle: ThemeObserver, EmptyStateViewStyle {
    var background: Color { theme.primaryUi01Active }
    var title: Color { theme.primaryText01 }
    var message: Color { theme.primaryText02 }
    var button: Color { theme.primaryInteractive01 }
}

class PlayerEmptyStateStyle: ThemeObserver, EmptyStateViewStyle {
    var background: Color { theme.playerContrast06 }
    var title: Color { theme.playerContrast01 }
    var message: Color { theme.playerContrast02 }
    var button: Color { theme.playerContrast01 }
}

extension EmptyStateViewStyle where Self == PlayerEmptyStateStyle {
    static var playerStyle: PlayerEmptyStateStyle {
        PlayerEmptyStateStyle()
    }
}

extension EmptyStateViewStyle where Self == DefaultEmptyStateStyle {
    static var defaultStyle: DefaultEmptyStateStyle {
        DefaultEmptyStateStyle()
    }
}

// MARK: - Preview

struct BookmarksEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarksEmptyStateView(style: .playerStyle)
    }
}
