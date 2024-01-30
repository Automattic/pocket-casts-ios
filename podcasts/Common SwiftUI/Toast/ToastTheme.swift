import SwiftUI

/// Allows customization of the Toast message colors
protocol ToastTheme: ObservableObject {
    var background: Color { get }
    var title: Color { get }
    var button: Color { get }
}

// MARK: - ToastPlayerTheme

/// A default theme for use in the full screen player
class ToastPlayerTheme: ThemeObserver, ToastTheme {
    var background: Color { theme.playerContrast01 }
    var title: Color { theme.playerBackground01 }
    var button: Color {
        // If the contrast between the background and highlight color is too low, then we'll default to the player background color
        let contrast = theme.playerHighlight01.contrast(with: background)
        return contrast > 2 ? theme.playerHighlight01 : theme.playerBackground01
    }
}

extension ToastTheme where Self == ToastPlayerTheme {
    static var playerTheme: ToastPlayerTheme {
        ToastPlayerTheme()
    }
}

// MARK: - ToastDefaultTheme

/// A default theme for use in the general app
class ToastDefaultTheme: ThemeObserver, ToastTheme {
    var background: Color { theme.playerContrast01 }
    var title: Color { theme.playerBackground01 }
    var button: Color { theme.playerHighlight01 }
}

extension ToastTheme where Self == ToastDefaultTheme {
    static var defaultTheme: ToastDefaultTheme {
        ToastDefaultTheme()
    }
}
