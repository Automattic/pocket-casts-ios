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

extension Button {
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
        } else {
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
        if #available(iOS 16.0, *) {
            baseContent(content: content)
                .scrollContentBackground(.hidden)
        } else {
            baseContent(content: content)
        }
    }

    private func baseContent(content: Content) -> some View {
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
    @Environment(\.appTheme) var theme

    let textColor: ThemeStyle

    init(textColor: ThemeStyle = .primaryInteractive02) {
        self.textColor = textColor
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .foregroundColor(AppTheme.color(for: textColor, theme: theme))
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? ThemeColor.primaryInteractive01(for: theme.activeTheme).color.opacity(0.6) : ThemeColor.primaryInteractive01(for: theme.activeTheme).color)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
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
        .cornerRadius(ViewConstants.buttonCornerRadius)
        .frame(height: 44)
    }
}

/// A dark button filled with a light color
struct RoundedDarkButton: ViewModifier {
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
        .background(ThemeColor.primaryText01(for: theme.activeTheme).color)
        .cornerRadius(ViewConstants.buttonCornerRadius)
        .frame(height: 44)
    }
}

/// A button that contains a stroke
struct StrokeButton: ViewModifier {
    @EnvironmentObject var theme: Theme

    func body(content: Content) -> some View {
        HStack {
            Spacer()
            content
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
            Spacer()
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                .stroke(ThemeColor.primaryText01(for: theme.activeTheme).color, lineWidth: ViewConstants.buttonStrokeWidth)
        )
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

struct SimpleTextButtonStyle: ButtonStyle {
    @Environment(\.appTheme) var theme

    let textColor: ThemeStyle

    init(textColor: ThemeStyle = .primaryText01) {
        self.textColor = textColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .foregroundColor(AppTheme.color(for: textColor, theme: theme))
            .frame(maxWidth: .infinity)
            .padding()
            .applyButtonEffect(isPressed: configuration.isPressed)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .contentShape(Rectangle())
    }
}

// MARK: - Button Modifiers
extension View {
    /// Adds a subtle spring effect when the `isPressed` value is changed
    /// This should be used from a `ButtonStyle` and passing in `configuration.isPressed`
    ///
    func applyButtonEffect(isPressed: Bool, enableHaptic: Bool = true) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0, anchor: .center)
            .animation(.interpolatingSpring(stiffness: 350, damping: 10, initialVelocity: 10), value: isPressed)
            .onChange(of: isPressed) { pressed in
                guard enableHaptic, pressed else { return }

                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
    }

    func applyButtonFont() -> some View {
        self.font(size: 18,
                  style: .body,
                  weight: .medium,
                  maxSizeCategory: .extraExtraLarge)
    }
}
