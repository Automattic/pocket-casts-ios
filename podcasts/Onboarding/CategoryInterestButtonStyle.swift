import SwiftUI

struct CategoryInterestButtonStyle: ButtonStyle {

    @EnvironmentObject var theme: Theme

    private enum Constants {
        enum Padding {
            static let roundedHorizontal: CGFloat = 20
            static let circleHorizontal: CGFloat = 8
            static let vertical: CGFloat = 8
        }

        static let cornerRadius: CGFloat = 24
    }

    // MARK: Colors
    private var border: Color {
        theme.primaryField03
    }

    private var background: Color {
        theme.primaryUi01
    }

    private var pressedBackground: Color {
        theme.primaryUi02Selected
    }

    private var foreground: Color {
        theme.secondaryText02
    }
    private var selectedBackground: Color {
        theme.secondaryIcon01
    }
    private var selectedForeground: Color {
        theme.primaryUi01
    }

    // MARK: View

    let isSelected: Bool
    let cornerStyle: CornerStyle

    enum CornerStyle {
        case rounded
        case circle

        var shape: some Shape {
            switch self {
                case .rounded:
                    AnyShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                case .circle:
                    AnyShape(Circle())
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
                case .rounded:
                    Constants.Padding.roundedHorizontal
                case .circle:
                    Constants.Padding.circleHorizontal
            }
        }
    }

    /// Used for generating previews with isPressed button state
    fileprivate var forcePressed = false

    init(isSelected: Bool = false, cornerStyle: CornerStyle = .rounded) {
        self.isSelected = isSelected
        self.cornerStyle = cornerStyle
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, cornerStyle.horizontalPadding)
            .padding(.vertical, Constants.Padding.vertical)
            .padding(cornerStyle == .circle ? 3 : 0)
            .cornerRadius(Constants.cornerRadius)
            .background(isSelected ? selectedBackground : ((configuration.isPressed || forcePressed) ? pressedBackground : background))
            .foregroundColor(isSelected ? selectedForeground : foreground)
            .overlay(
                cornerStyle.shape
                    .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
            )
            .clipShape(cornerStyle.shape)
    }
}

// MARK: Previews

#Preview("normal") {
    Button("Hello", action: {

    }).buttonStyle(CategoryInterestButtonStyle(isSelected: false))
        .previewWithAllThemes()
}
