import SwiftUI

struct CategoryButtonStyle: ButtonStyle {

    @EnvironmentObject var theme: Theme

    private enum Constants {
        enum Padding {
            static let horizontal: CGFloat = 20
            static let vertical: CGFloat = 8
        }

        static let cornerRadius: CGFloat = 24
    }

    // MARK: Colors
    private var border: Color {
        theme.primaryIcon02
    }

    private var background: Color {
        theme.primaryUi01
    }

    private var pressedBackground: Color {
        theme.primaryUi02Selected
    }

    private var foreground: Color {
        theme.primaryText01
    }
    private var selectedBackground: Color {
        theme.secondaryIcon01
    }
    private var selectedForeground: Color {
        theme.secondaryUi01
    }

    // MARK: View

    let isSelected: Bool
 
    /// Used for generating previews with isPressed button state
    fileprivate var forcePressed = false

    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, Constants.Padding.horizontal)
            .padding(.vertical, Constants.Padding.vertical)
            .cornerRadius(Constants.cornerRadius)
            .background(isSelected ? selectedBackground : ((configuration.isPressed || forcePressed) ? pressedBackground : background))
            .foregroundColor(isSelected ? selectedForeground : foreground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

// MARK: Previews

#Preview("normal") {
    Button("Hello", action: {

    }).buttonStyle(CategoryButtonStyle(isSelected: false))
    .previewWithAllThemes()
}

#Preview("selected") {
    Button("Hello", action: {

    }).buttonStyle(CategoryButtonStyle(isSelected: true))
    .previewWithAllThemes()
}

#Preview("pressed") {
    var buttonStyle = CategoryButtonStyle(isSelected: false)
    buttonStyle.forcePressed = true
    return Button("Hello", action: {

    }).buttonStyle(buttonStyle)
    .applyButtonEffect(isPressed: true)
    .previewWithAllThemes()
}
