import SwiftUI

// MARK: - PlayerActionBarStyle

/// A style that should be used if the action bar appears in the full screen player
struct PlayerActionBarStyle: ActionBarStyle {
    @ObservedObject private var theme: Theme = .sharedTheme

    var backgroundTint: Color {
        theme.playerBackground02
    }

    var buttonColor: Color {
        theme.playerBackground01
    }

    var foregroundColor: Color {
        theme.playerContrast01
    }
}

extension ActionBarStyle where Self == PlayerActionBarStyle {
    static var player: PlayerActionBarStyle {
        PlayerActionBarStyle()
    }
}
