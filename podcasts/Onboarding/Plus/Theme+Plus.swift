import SwiftUI
import UIKit

extension Theme {
    var plusPrimaryColor: Color {
        Color(hex: "FEB525")
    }

    var patronPrimaryColor: Color {
        Color(hex: ThemeConstants.patronHexLightTheme)
    }
}

// MARK: - AppTheme

extension AppTheme {
    static var patronTextColor: UIColor {
        let hex = Theme.isDarkTheme() ? ThemeConstants.patronHexDarkTheme : ThemeConstants.patronHexLightTheme

        return UIColor(hex: hex)
    }
}

// MARK: - Constants
private enum ThemeConstants {
    static let patronHexLightTheme = "#6046F5"
    static let patronHexDarkTheme = "#AFA2FA"
}
