import SwiftUI

/// A big extension to add more ease of access to themed colors in SwiftUI directly from the Theme environment
///
/// Usage:
///
/// struct TestView: View {
///     @EnvironmentObject var theme: Theme
///
///     var body: some View {
///         VStack {
///             Text("Old Way ☹️").foregroundColor(AppTheme.color(for: .primaryText01, theme: theme))
///
///             Text("New Way 🦄").foregroundColor(theme.primaryText01)
///         }
///     }
/// }
///
extension Theme {
    var primaryText01: Color {
        AppTheme.color(for: .primaryText01, theme: self)
    }

    var primaryText02: Color {
        AppTheme.color(for: .primaryText02, theme: self)
    }

    var primaryUi01: Color {
        AppTheme.color(for: .primaryUi01, theme: self)
    }

    var primaryUi01Active: Color {
        AppTheme.color(for: .primaryUi01Active, theme: self)
    }

    var primaryUi02: Color {
        AppTheme.color(for: .primaryUi02, theme: self)
    }

    var primaryUi02Selected: Color {
        AppTheme.color(for: .primaryUi02Selected, theme: self)
    }

    var primaryUi02Active: Color {
        AppTheme.color(for: .primaryUi02Active, theme: self)
    }

    var primaryUi03: Color {
        AppTheme.color(for: .primaryUi03, theme: self)
    }

    var primaryUi04: Color {
        AppTheme.color(for: .primaryUi04, theme: self)
    }

    var primaryUi05: Color {
        AppTheme.color(for: .primaryUi05, theme: self)
    }

    var primaryUi05Selected: Color {
        AppTheme.color(for: .primaryUi05Selected, theme: self)
    }

    var primaryUi06: Color {
        AppTheme.color(for: .primaryUi06, theme: self)
    }

    var primaryIcon01: Color {
        AppTheme.color(for: .primaryIcon01, theme: self)
    }

    var primaryIcon01Active: Color {
        AppTheme.color(for: .primaryIcon01Active, theme: self)
    }

    var primaryIcon02: Color {
        AppTheme.color(for: .primaryIcon02, theme: self)
    }

    var primaryIcon02Selected: Color {
        AppTheme.color(for: .primaryIcon02Selected, theme: self)
    }

    var primaryIcon02Active: Color {
        AppTheme.color(for: .primaryIcon02Active, theme: self)
    }

    var primaryIcon03: Color {
        AppTheme.color(for: .primaryIcon03, theme: self)
    }

    var primaryIcon03Active: Color {
        AppTheme.color(for: .primaryIcon03Active, theme: self)
    }

    var primaryText02Selected: Color {
        AppTheme.color(for: .primaryText02Selected, theme: self)
    }

    var primaryField01: Color {
        AppTheme.color(for: .primaryField01, theme: self)
    }

    var primaryField01Active: Color {
        AppTheme.color(for: .primaryField01Active, theme: self)
    }

    var primaryField02: Color {
        AppTheme.color(for: .primaryField02, theme: self)
    }

    var primaryField02Active: Color {
        AppTheme.color(for: .primaryField02Active, theme: self)
    }

    var primaryField03: Color {
        AppTheme.color(for: .primaryField03, theme: self)
    }

    var primaryField03Active: Color {
        AppTheme.color(for: .primaryField03Active, theme: self)
    }

    var primaryInteractive01: Color {
        AppTheme.color(for: .primaryInteractive01, theme: self)
    }

    var primaryInteractive01Hover: Color {
        AppTheme.color(for: .primaryInteractive01Hover, theme: self)
    }

    var primaryInteractive01Active: Color {
        AppTheme.color(for: .primaryInteractive01Active, theme: self)
    }

    var primaryInteractive01Disabled: Color {
        AppTheme.color(for: .primaryInteractive01Disabled, theme: self)
    }

    var primaryInteractive02: Color {
        AppTheme.color(for: .primaryInteractive02, theme: self)
    }

    var primaryInteractive02Hover: Color {
        AppTheme.color(for: .primaryInteractive02Hover, theme: self)
    }

    var primaryInteractive02Active: Color {
        AppTheme.color(for: .primaryInteractive02Active, theme: self)
    }

    var primaryInteractive03: Color {
        AppTheme.color(for: .primaryInteractive03, theme: self)
    }

    var secondaryUi01: Color {
        AppTheme.color(for: .secondaryUi01, theme: self)
    }

    var secondaryUi02: Color {
        AppTheme.color(for: .secondaryUi02, theme: self)
    }

    var secondaryIcon01: Color {
        AppTheme.color(for: .secondaryIcon01, theme: self)
    }

    var secondaryIcon02: Color {
        AppTheme.color(for: .secondaryIcon02, theme: self)
    }

    var secondaryText01: Color {
        AppTheme.color(for: .secondaryText01, theme: self)
    }

    var secondaryText02: Color {
        AppTheme.color(for: .secondaryText02, theme: self)
    }

    var secondaryField01: Color {
        AppTheme.color(for: .secondaryField01, theme: self)
    }

    var secondaryField01Active: Color {
        AppTheme.color(for: .secondaryField01Active, theme: self)
    }

    var secondaryInteractive01: Color {
        AppTheme.color(for: .secondaryInteractive01, theme: self)
    }

    var secondaryInteractive01Hover: Color {
        AppTheme.color(for: .secondaryInteractive01Hover, theme: self)
    }

    var secondaryInteractive01Active: Color {
        AppTheme.color(for: .secondaryInteractive01Active, theme: self)
    }

    var support01: Color {
        AppTheme.color(for: .support01, theme: self)
    }

    var support02: Color {
        AppTheme.color(for: .support02, theme: self)
    }

    var support03: Color {
        AppTheme.color(for: .support03, theme: self)
    }

    var support04: Color {
        AppTheme.color(for: .support04, theme: self)
    }

    var support05: Color {
        AppTheme.color(for: .support05, theme: self)
    }

    var support06: Color {
        AppTheme.color(for: .support06, theme: self)
    }

    var support07: Color {
        AppTheme.color(for: .support07, theme: self)
    }

    var support08: Color {
        AppTheme.color(for: .support08, theme: self)
    }

    var support09: Color {
        AppTheme.color(for: .support09, theme: self)
    }

    var support10: Color {
        AppTheme.color(for: .support10, theme: self)
    }

    var playerContrast01: Color {
        AppTheme.color(for: .playerContrast01, theme: self)
    }

    var playerContrast02: Color {
        AppTheme.color(for: .playerContrast02, theme: self)
    }

    var playerContrast03: Color {
        AppTheme.color(for: .playerContrast03, theme: self)
    }

    var playerContrast04: Color {
        AppTheme.color(for: .playerContrast04, theme: self)
    }

    var playerContrast05: Color {
        AppTheme.color(for: .playerContrast05, theme: self)
    }

    var playerContrast06: Color {
        AppTheme.color(for: .playerContrast06, theme: self)
    }

    var contrast01: Color {
        AppTheme.color(for: .contrast01, theme: self)
    }

    var contrast02: Color {
        AppTheme.color(for: .contrast02, theme: self)
    }

    var contrast03: Color {
        AppTheme.color(for: .contrast03, theme: self)
    }

    var contrast04: Color {
        AppTheme.color(for: .contrast04, theme: self)
    }

    var filter01: Color {
        AppTheme.color(for: .filter01, theme: self)
    }

    var filter02: Color {
        AppTheme.color(for: .filter02, theme: self)
    }

    var filter03: Color {
        AppTheme.color(for: .filter03, theme: self)
    }

    var filter04: Color {
        AppTheme.color(for: .filter04, theme: self)
    }

    var filter05: Color {
        AppTheme.color(for: .filter05, theme: self)
    }

    var filter06: Color {
        AppTheme.color(for: .filter06, theme: self)
    }

    var filter07: Color {
        AppTheme.color(for: .filter07, theme: self)
    }

    var filter08: Color {
        AppTheme.color(for: .filter08, theme: self)
    }

    var veil: Color {
        AppTheme.color(for: .veil, theme: self)
    }

    var gradient01A: Color {
        AppTheme.color(for: .gradient01A, theme: self)
    }

    var gradient01E: Color {
        AppTheme.color(for: .gradient01E, theme: self)
    }

    var gradient02A: Color {
        AppTheme.color(for: .gradient02A, theme: self)
    }

    var gradient02E: Color {
        AppTheme.color(for: .gradient02E, theme: self)
    }

    var gradient03A: Color {
        AppTheme.color(for: .gradient03A, theme: self)
    }

    var gradient03E: Color {
        AppTheme.color(for: .gradient03E, theme: self)
    }

    var gradient04A: Color {
        AppTheme.color(for: .gradient04A, theme: self)
    }

    var gradient04E: Color {
        AppTheme.color(for: .gradient04E, theme: self)
    }

    var gradient05A: Color {
        AppTheme.color(for: .gradient05A, theme: self)
    }

    var gradient05E: Color {
        AppTheme.color(for: .gradient05E, theme: self)
    }

    var imageFilter01: Color {
        AppTheme.color(for: .imageFilter01, theme: self)
    }

    var imageFilter02: Color {
        AppTheme.color(for: .imageFilter02, theme: self)
    }

    var imageFilter03: Color {
        AppTheme.color(for: .imageFilter03, theme: self)
    }

    var imageFilter04: Color {
        AppTheme.color(for: .imageFilter04, theme: self)
    }

    var category01: Color {
        AppTheme.color(for: .category01, theme: self)
    }

    var category02: Color {
        AppTheme.color(for: .category02, theme: self)
    }

    var category03: Color {
        AppTheme.color(for: .category03, theme: self)
    }

    var category04: Color {
        AppTheme.color(for: .category04, theme: self)
    }

    var category05: Color {
        AppTheme.color(for: .category05, theme: self)
    }

    var category06: Color {
        AppTheme.color(for: .category06, theme: self)
    }

    var category07: Color {
        AppTheme.color(for: .category07, theme: self)
    }

    var category08: Color {
        AppTheme.color(for: .category08, theme: self)
    }

    var category09: Color {
        AppTheme.color(for: .category09, theme: self)
    }

    var category10: Color {
        AppTheme.color(for: .category10, theme: self)
    }

    var category11: Color {
        AppTheme.color(for: .category11, theme: self)
    }

    var category12: Color {
        AppTheme.color(for: .category12, theme: self)
    }

    var category13: Color {
        AppTheme.color(for: .category13, theme: self)
    }

    var category14: Color {
        AppTheme.color(for: .category14, theme: self)
    }

    var category15: Color {
        AppTheme.color(for: .category15, theme: self)
    }

    var category16: Color {
        AppTheme.color(for: .category16, theme: self)
    }

    var category17: Color {
        AppTheme.color(for: .category17, theme: self)
    }

    var category18: Color {
        AppTheme.color(for: .category18, theme: self)
    }

    var category19: Color {
        AppTheme.color(for: .category19, theme: self)
    }
}
