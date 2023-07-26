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

    var titleColor: Color {
        theme.playerContrast01
    }

    var iconColor: Color {
        theme.playerContrast01
    }
}

extension ActionBarStyle where Self == PlayerActionBarStyle {
    static var player: PlayerActionBarStyle {
        PlayerActionBarStyle()
    }
}

// MARK: - ThemedActionBarStyle

/// A style that should be used if the action bar appears in the full screen player
struct ThemedActionBarStyle: ActionBarStyle {
    @ObservedObject private var theme: Theme = .sharedTheme

    var backgroundTint: Color {
        theme.secondaryUi01
    }

    var buttonColor: Color {
        theme.primaryInteractive01
    }

    var titleColor: Color {
        theme.primaryText01
    }

    var iconColor: Color {
        theme.primaryInteractive02
    }
}

extension ActionBarStyle where Self == ThemedActionBarStyle {
    static var themed: ThemedActionBarStyle {
        ThemedActionBarStyle()
    }
}
