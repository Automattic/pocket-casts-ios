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
        theme.primaryField03
    }
    private var background: Color {
        theme.primaryUi02Active
    }
    private var foreground: Color {
        theme.primaryText01
    }
    private var selectedBackground: Color {
        theme.primaryField03Active
    }
    private var selectedForeground: Color {
        theme.primaryUi01
    }

    // MARK: View

    let isSelected: Bool

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
            .background(isSelected ? selectedBackground : (configuration.isPressed ? background : Color.clear))
            .foregroundColor(isSelected ? selectedForeground : foreground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}
