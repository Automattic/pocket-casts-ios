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
        content
            .listRowSeparator(.hidden)
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
struct BasicButtonStyle: ButtonStyle {
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color?

    init(textColor: Color, backgroundColor: Color, borderColor: Color? = nil) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
            .modify {
                if let borderColor {
                    $0.overlay {
                        RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                            .stroke(borderColor)
                    }
                } else {
                    $0
                }
            }
    }
}

struct RoundedButtonStyle: ButtonStyle {
    @ObservedObject var theme: Theme
    let textColor: ThemeStyle
    let backgroundColor: Color?

    init(theme: Theme, textColor: ThemeStyle = .primaryInteractive02, backgroundColor: Color? = nil) {
        self.theme = theme
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        let text = AppTheme.color(for: textColor, theme: theme)
        let background = backgroundColor ?? AppTheme.color(for: .primaryInteractive01, theme: theme)
                            .opacity(configuration.isPressed ? 0.6 : 1)

        BasicButtonStyle(textColor: text, backgroundColor: background)
            .makeBody(configuration: configuration)
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
struct RoundedDarkButton: ButtonStyle {
    @ObservedObject var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding()

            .foregroundColor(ThemeColor.primaryUi01(for: theme.activeTheme).color)
            .background(ThemeColor.primaryText01(for: theme.activeTheme).color)

            .cornerRadius(ViewConstants.buttonCornerRadius)
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// A button that contains a stroke
struct StrokeButton: ButtonStyle {
    let textColor: Color
    let backgroundColor: Color
    let strokeColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                    .stroke(strokeColor, lineWidth: ViewConstants.buttonStrokeWidth)
            )
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
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
    @ObservedObject var theme: Theme

    let textColor: ThemeStyle
    let style: Font.TextStyle
    let weight: Font.Weight
    let size: Double

    init(theme: Theme,
         size: Double = 18,
         textColor: ThemeStyle = .primaryText01,
         style: Font.TextStyle = .body,
         weight: Font.Weight = .semibold) {
        self.theme = theme
        self.size = size
        self.textColor = textColor
        self.style = style
        self.weight = weight
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont(size: size, style: style, weight: weight)
            .foregroundColor(AppTheme.color(for: textColor, theme: theme))
            .frame(maxWidth: .infinity)
            .padding()
            .applyButtonEffect(isPressed: configuration.isPressed)
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .contentShape(Rectangle())
    }
}

struct ClickyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonEffect(isPressed: configuration.isPressed)
    }
}

/// Default button style for buttons with images
struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(ThemeColor.primaryIcon01(for: theme.activeTheme).color.opacity(configuration.isPressed ? 0.4 : 1))
    }
}

/// Default button style for buttons with images
struct SecondaryButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    var highlightColor: Color {
        AppTheme.colorForStyle(.primaryText01, themeOverride: theme.activeTheme).color
    }

    var defaultColor: Color {
        AppTheme.colorForStyle(.primaryIcon02, themeOverride: theme.activeTheme).color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? highlightColor : defaultColor)
    }
}

/// Default style for buttons used as tappable cell area
struct ListCellButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    var highlightColor: Color {
        AppTheme.colorForStyle(.primaryUi02Active, themeOverride: theme.activeTheme).color
    }

    var defaultColor: Color {
        AppTheme.colorForStyle(.primaryUi02, themeOverride: theme.activeTheme).color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? highlightColor : defaultColor)
    }
}


// MARK: - Button Modifiers
extension View {
    /// Adds a subtle spring effect when the `isPressed` value is changed
    /// This should be used from a `ButtonStyle` and passing in `configuration.isPressed`
    ///
    func applyButtonEffect(isPressed: Bool, enableHaptic: Bool = true, scaleEffectNumber: Double = 0.98) -> some View {
        self
            .scaleEffect(isPressed ? scaleEffectNumber : 1.0, anchor: .center)
            .animation(.interpolatingSpring(stiffness: 350, damping: 10, initialVelocity: 10), value: isPressed)
            .onChange(of: isPressed) { pressed in
                guard enableHaptic, pressed else { return }

                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
    }

    func applyButtonFont(size: Double = 18,
                         style: Font.TextStyle = .body,
                         weight: Font.Weight = .semibold) -> some View {
        self.font(size: size,
                  style: style,
                  weight: weight,
                  maxSizeCategory: .extraExtraLarge)
    }
}

// MARK: - Pill used in the top of the modals

struct ModalTopPill: View {
    let fillColor: Color

    init(fillColor: Color = .white) {
        self.fillColor = fillColor
    }

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .frame(width: Constants.pillSize.width, height: Constants.pillSize.height)
            .cornerRadius(Constants.pillCornerRadius)
            .padding(.top, Constants.pillTopPadding)
            .opacity(Constants.pillOpacity)
    }

    private enum Constants {
        static let pillSize: CGSize = .init(width: 60, height: 4)
        static let pillCornerRadius: CGFloat = 10
        static let pillTopPadding: CGFloat = 8
        static let pillOpacity: CGFloat = 0.2
    }
}
