import SwiftUI

struct PlusGradientFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .updateFont()
            .frame(maxWidth: .infinity)
            .padding()

            .background(Color.plusGradient)
            .foregroundColor(Color.filledTextColor)

            .cornerRadius(ViewConfig.cornerRadius)
            .makeSpringy(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

struct PlusGradientStrokeButton: ButtonStyle {
    let isSelectable: Bool
    let isSelected: Bool

    init(isSelectable: Bool = false, isSelected: Bool = true) {
        self.isSelectable = isSelectable
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .updateFont()
            .frame(maxWidth: .infinity)
            .padding()

            // Overlay the gradient, or just set the color if not selected
            .foregroundColor(isSelected ? nil : Color.unselectedColor)
            .gradientOverlay(isSelected ? Color.plusGradient : nil)

            // Stroke Overlay + Image if needed
            .overlay(
                ZStack {
                    if isSelected {
                        // Only show the image if we're selectable
                        if isSelectable {
                            HStack {
                                Spacer()
                                Image("icon-plus-button-selected").padding(.trailing)
                            }
                        }

                        RoundedRectangle(cornerRadius: ViewConfig.cornerRadius).stroke(Color.plusGradient, lineWidth: ViewConfig.strokeWidth)
                    } else {
                        RoundedRectangle(cornerRadius: ViewConfig.cornerRadius).stroke(Color.unselectedColor, lineWidth: ViewConfig.strokeWidth)
                    }
                }
            )

            // Fade out the button if needed
            .opacity(isSelected ? 1 : 0.4)
            .animation(.linear(duration: 0.14), value: isSelected)

            // Make the button interactable
            .makeSpringy(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

private extension View {
    func gradientOverlay<Content: View>(_ content: Content) -> some View {
        self.overlay(content).mask(self)
    }

    func updateFont() -> some View {
        self.font(size: 18,
                  style: .body,
                  weight: .medium,
                  maxSizeCategory: .extraExtraLarge)
    }
}

private extension Color {
    static let plusGradient = LinearGradient(gradient: Gradient(colors: [Color(hex: "FED745"), Color(hex: "FEB525")]),
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    static let unselectedColor = Color.white
    static let filledTextColor = Color.black
}

private enum ViewConfig {
    static let cornerRadius = 12.0
    static let strokeWidth = 2.0
}
