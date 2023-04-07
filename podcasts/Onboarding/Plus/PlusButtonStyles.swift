import SwiftUI

struct PlusGradientFilledButtonStyle: ButtonStyle {
    let isLoading: Bool
    let background: any View
    let foregroundColor: Color

    init(isLoading: Bool = false, background: any View = Color.plusGradient, foregroundColor: Color = .plusButtonFilledTextColor) {
        self.isLoading = isLoading
        self.background = background
        self.foregroundColor = foregroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding()

            .background(AnyView(background))
            .foregroundColor(foregroundColor)

            .cornerRadius(ViewConstants.buttonCornerRadius)
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
            .overlay(
                ZStack {
                    if isLoading {
                        Rectangle()
                            .overlay(AnyView(background))
                            .cornerRadius(ViewConstants.buttonCornerRadius)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                    }
                }
            )
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
            .foregroundColor(isSelected ? Color.plusGradientColor1 : Color.plusButtonUnselectedColor)
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
                        RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius).stroke(Color.plusButtonUnselectedColor, lineWidth: ViewConstants.buttonStrokeWidth)
                    }
                }
            )

            // Fade out the button if needed
            .opacity(isSelected ? 1 : 0.4)
            .animation(.easeIn(duration: 0.14), value: isSelected)

            // Make the button interactable
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

struct PlusFreeTrialLabel: View {
    let text: String
    let isSelected: Bool
    init(_ text: String, isSelected: Bool = true) {
        self.text = text
        self.isSelected = isSelected
    }

    var body: some View {
        Text(L10n.freeTrialDurationFreeTrial(text.localizedUppercase))
            .font(size: 12, style: .caption, weight: .semibold, maxSizeCategory: .extraExtraLarge)
            .multilineTextAlignment(.center)
            .padding([.top, .bottom], 4)
            .padding([.leading, .trailing], 13)
            .background(
                Color.plusGradient.cornerRadius(4)
            )
            .foregroundColor(Color.plusButtonFilledTextColor)
            .grayscale(isSelected ? 0 : 1)
            .animation(.easeInOut, value: isSelected)
    }
}

extension View {
    func gradientOverlay<Content: View>(_ content: Content) -> some View {
        self.overlay(content).mask(self)
    }
}

extension Color {
    static let plusGradient = LinearGradient(stops: [
        Gradient.Stop(color: .plusGradientColor1, location: 0.0822),
        Gradient.Stop(color: .plusGradientColor2, location: 0.9209)
    ], startPoint: .topLeading, endPoint: .topTrailing)

    static let plusGradientColor1 = Color(hex: "FED745")
    static let plusGradientColor2 = Color(hex: "FEB525")

    static let plusButtonUnselectedColor = Color.white
    static let plusButtonFilledTextColor = Color.black

    static let plusBackgroundColor = Color(hex: "121212")
    static let plusLeftCircleColor = Color(hex: "ffd845")
    static let plusRightCircleColor = Color(hex: "ffb626")
}
