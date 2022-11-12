import SwiftUI

struct PlusGradientFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding()

            .background(Color.plusGradient)
            .foregroundColor(Color.filledTextColor)

            .cornerRadius(ViewConstants.buttonCornerRadius)
            .applyButtonEffect(isPressed: configuration.isPressed)
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
            .applyButtonFont()
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

                        RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius).stroke(Color.plusGradient, lineWidth: ViewConstants.buttonStrokeWidth)
                    } else {
                        RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius).stroke(Color.unselectedColor, lineWidth: ViewConstants.buttonStrokeWidth)
                    }
                }
            )

            // Fade out the button if needed
            .opacity(isSelected ? 1 : 0.4)
            .animation(.linear(duration: 0.14), value: isSelected)

            // Make the button interactable
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

private extension View {
    func gradientOverlay<Content: View>(_ content: Content) -> some View {
        self.overlay(content).mask(self)
    }
}

private extension Color {
    static let unselectedColor = Color.white
    static let filledTextColor = Color.black
    static let plusGradient = LinearGradient(stops: [
        Gradient.Stop(color: .plusGradientColor1, location: 0.0822),
        Gradient.Stop(color: .plusGradientColor2, location: 0.9209)
    ], startPoint: .topLeading, endPoint: .topTrailing)
}
