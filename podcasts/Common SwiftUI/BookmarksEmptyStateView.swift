import SwiftUI

/// Displays the empty state view for the bookmarks
struct BookmarksEmptyStateView<Style: EmptyStateViewStyle>: View {
    @EnvironmentObject var viewModel: BookmarkListViewModel
    @ObservedObject var style: Style

    var title: String = L10n.noBookmarksTitle
    var message: String = L10n.noBookmarksMessage
    var actionTitle: String = L10n.noBookmarksButtonTitle
    var action: (() -> Void)? = nil

    var body: some View {
        EmptyStateView(title: title, message: message, icon: { Image("bookmarks-profile") }, actions: [
            .init(title: actionTitle, action: {
                guard let action else {
                    viewModel.openHeadphoneSettings()
                    return
                }

                action()
            })
        ], style: style, maxContentWidth: .infinity)
    }
}

// MARK: - Styles

class DefaultEmptyStateStyle: ThemeObserver, EmptyStateViewStyle {
    var title: Color { theme.primaryText01 }
    var message: Color { theme.primaryText02 }
    var icon: Color { theme.primaryIcon03 }
    var button: Color { theme.primaryInteractive01 }
}

class PlayerEmptyStateStyle: ThemeObserver, EmptyStateViewStyle {
    var title: Color { theme.playerContrast01 }
    var message: Color { theme.playerContrast02 }
    var icon: Color { theme.primaryIcon03 }
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
