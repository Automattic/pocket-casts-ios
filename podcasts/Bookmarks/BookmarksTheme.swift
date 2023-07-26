import SwiftUI
import Combine

protocol BookmarksStyle: ObservableObject {
    associatedtype ActionStyle = ActionBarStyle

    var background: Color { get }
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }
    var divider: Color { get }
    var rowHighlight: Color { get }
    var rowSelected: Color { get }
    var selectButtonStroke: Color { get }
    var selectButton: Color { get }
    var selectCheck: Color { get }
    var playButtonText: Color { get }
    var playButtonBackground: Color? { get }
    var playButtonStroke: Color? { get }
    var actionBarStyle: ActionStyle { get }
}

// MARK: - ThemeObserver

class ThemeObserver: ObservableObject {
    let theme: Theme = .sharedTheme
    private var cancellables = Set<AnyCancellable>()

    init() {
        Constants.Notifications.themeChanged.publisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Player Style

class BookmarksPlayerTabStyle: ThemeObserver, BookmarksStyle {
    var background: Color { theme.playerBackground01 }
    var primaryText: Color { theme.playerContrast01 }
    var secondaryText: Color { theme.playerContrast02 }
    var tertiaryText: Color { theme.playerContrast02 }
    var divider: Color { theme.playerContrast05 }
    var rowHighlight: Color { theme.playerContrast05 }
    var rowSelected: Color { rowHighlight }
    var selectButton: Color { theme.playerContrast01 }
    var selectButtonStroke: Color { theme.playerContrast01 }
    var selectCheck: Color { theme.playerBackground01 }
    var playButtonText: Color { theme.playerBackground01 }
    var playButtonBackground: Color? { theme.playerContrast01 }
    var playButtonStroke: Color? = nil
    var actionBarStyle = PlayerActionBarStyle()
}

// MARK: - Default Themed Style

class ThemedBookmarksStyle: ThemeObserver, BookmarksStyle {
    var background: Color { theme.primaryUi01 }
    var primaryText: Color { theme.primaryText01 }
    var secondaryText: Color { theme.primaryText02 }
    var tertiaryText: Color { theme.primaryText02 }
    var divider: Color { theme.primaryUi05 }
    var rowHighlight: Color { theme.primaryUi02Active }
    var rowSelected: Color { theme.primaryUi02Selected }
    var selectButtonStroke: Color { theme.primaryIcon02 }
    var selectButton: Color { theme.primaryInteractive01 }
    var selectCheck: Color { theme.primaryInteractive02 }
    var playButtonText: Color { theme.primaryText01 }
    var playButtonBackground: Color? { theme.primaryUi01 }
    var playButtonStroke: Color? { theme.primaryText01 }
    var actionBarStyle = ThemedActionBarStyle()
}
