import SwiftUI

struct CategoryButtonStyle: ButtonStyle {

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
    let cornerStyle: CornerStyle

    enum CornerStyle {
        case rounded
        case circle

        @available(iOS 16.0, *)
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
            .cornerRadius(Constants.cornerRadius)
            .background(isSelected ? selectedBackground : (configuration.isPressed ? background : Color.clear))
            .foregroundColor(isSelected ? selectedForeground : foreground)
            .modify {
                if #available(iOS 16.0, *) {
                    $0
                        .padding(cornerStyle == .circle ? 3 : 0)
                        .overlay(
                        cornerStyle.shape
                            .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
                    )
                    .clipShape(cornerStyle.shape)
                } else {
                    $0.overlay(
                        RoundedRectangle(cornerRadius: Constants.cornerRadius)
                            .stroke(isSelected ? selectedBackground : border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                }
            }
    }
}
