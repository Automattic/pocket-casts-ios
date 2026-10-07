import SwiftUI

/// Allows customization of the Toast message colors
protocol ToastTheme: ObservableObject {
    var background: Color { get }
    var title: Color { get }
    var button: Color { get }
    var iconColor: Color? { get }
    var iconName: String? { get }
}

// MARK: - ToastPlayerTheme

/// A default theme for use in the full screen player
class ToastPlayerTheme: ThemeObserver, ToastTheme {
    var background: Color { LiquidGlass.isEnabled ? theme.playerBackground01 : theme.playerContrast01 }
    var title: Color { LiquidGlass.isEnabled ? theme.playerContrast01 : theme.playerBackground01 }
    var iconName: String? { nil }
    var iconColor: Color? { nil }
    var button: Color {
        if LiquidGlass.isEnabled {
            // The glass is tinted with the player background, so fall back to the title color when the podcast tint is too dark to read on it
            return theme.playerHighlight01.contrast(with: background) > 2 ? theme.playerHighlight01 : theme.playerContrast01
        }

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
    var background: Color { LiquidGlass.isEnabled ? theme.primaryUi01 : theme.playerContrast01 }
    var title: Color { LiquidGlass.isEnabled ? theme.primaryText01 : theme.playerBackground01 }
    var iconColor: Color? { nil }
    var iconName: String? { nil }
    var button: Color {
        if LiquidGlass.isEnabled {
            return theme.primaryInteractive01
        }

        // If the contrast between the background and highlight color is too low, then we'll switch to interactive 02
        let contrast = theme.primaryInteractive01.contrast(with: background)
        return contrast > 2 ? theme.primaryInteractive01 : theme.primaryInteractive02
    }
}

extension ToastTheme where Self == ToastDefaultTheme {
    static var defaultTheme: ToastDefaultTheme {
        ToastDefaultTheme()
    }
}

// MARK: - ToastIconTheme

/// A default theme for use in the general app
class ToastIconTheme: ThemeObserver, ToastTheme {
    var background: Color { LiquidGlass.isEnabled ? theme.primaryUi01 : theme.playerContrast01 }
    var title: Color { LiquidGlass.isEnabled ? theme.primaryText01 : theme.playerBackground01 }
    var button: Color { LiquidGlass.isEnabled ? theme.primaryInteractive01 : theme.primaryText02Selected }
    let iconName: String?
    let iconColor: Color?

    init(iconName: String, iconColor: Color) {
        self.iconName = iconName
        self.iconColor = iconColor
        super.init()
    }
}
