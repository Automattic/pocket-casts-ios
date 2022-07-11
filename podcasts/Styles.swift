import Foundation
import SwiftUI

// MARK: - Multiple View Types

struct DefaultThemeSettings: ViewModifier {
    @EnvironmentObject var theme: Theme
    let backgroundOverride: ThemeStyle

    init(backgroundOverride: ThemeStyle = .primaryUi01) {
        self.backgroundOverride = backgroundOverride
    }

    func body(content: Content) -> some View {
        content
            .background(AppTheme.colorForStyle(backgroundOverride, themeOverride: theme.activeTheme).color.ignoresSafeArea())
            .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
    }
}

// MARK: - Text

struct PrimaryText: ViewModifier {
    @EnvironmentObject var theme: Theme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
    }
}

struct SecondaryText: ViewModifier {
    @EnvironmentObject var theme: Theme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(ThemeColor.primaryText02(for: theme.activeTheme).color)
    }
}

extension Text {
    func textStyle<Style: ViewModifier>(_ style: Style) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}

struct HiddenListDividers: ViewModifier {
    @EnvironmentObject var theme: Theme
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .listRowSeparator(.hidden)
        }
        else {
            content
        }
    }
}

extension View {
    func hideListRowSeperators() -> some View {
        ModifiedContent(content: self, modifier: HiddenListDividers())
    }
}

struct RequiredFieldStyle: TextFieldStyle {
    let hasErrored: Bool
    @EnvironmentObject var theme: Theme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .colorScheme(Theme.isDarkTheme() ? .dark : .light)
            .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
            .padding(6)
            .required(hasErrored)
            .background(ThemeColor.primaryUi02(for: theme.activeTheme).color.cornerRadius(ViewConstants.cornerRadius))
    }
}

struct RequiredInput: ViewModifier {
    @EnvironmentObject var theme: Theme
    let hasErrored: Bool

    init(_ hasErrored: Bool) {
        self.hasErrored = hasErrored
    }

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: ViewConstants.cornerRadius).stroke(
                hasErrored ? .red : ThemeColor.primaryUi05(for: theme.activeTheme).color,
                lineWidth: 1
            )
        )
    }
}

struct ThemedTextField: ViewModifier {
    @EnvironmentObject var theme: Theme
    let style: ThemeStyle
    let hasErrored: Bool

    init(style: ThemeStyle = .primaryUi02, hasErrored: Bool = false) {
        self.style = style
        self.hasErrored = hasErrored
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
            .padding(10)
            .required(hasErrored)
            .background(AppTheme.colorForStyle(style, themeOverride: theme.activeTheme).color.cornerRadius(ViewConstants.cornerRadius))
    }
}

struct ThemedDivider: View {
    @EnvironmentObject var theme: Theme
    
    var body: some View {
        Divider()
            .background(ThemeColor.primaryUi05(for: theme.activeTheme).color)
    }
}

// MARK: - Button

struct RoundedButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme
    
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.white)
            Spacer()
        }
        .padding()
        .background(configuration.isPressed ? ThemeColor.primaryInteractive01(for: theme.activeTheme).color.opacity(0.6) : ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
        .cornerRadius(10)
        .scaleEffect(configuration.isPressed ? 0.99 : 1)
        .frame(height: 44)
    }
}

struct RoundedButton: ViewModifier {
    @EnvironmentObject var theme: Theme
    
    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ThemeColor.primaryUi01(for: theme.activeTheme).color)
            Spacer()
        }
        .padding()
        .background(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
        .cornerRadius(10)
        .frame(height: 44)
    }
}

struct NavButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
            .font(.headline)
            .opacity(isEnabled ? 1 : 0.4)
    }
}
