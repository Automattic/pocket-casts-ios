import SwiftUI

struct PlusOpaqueButtonStyle: ButtonStyle {
    let isLoading: Bool
    let plan: Plan

    private var background: Color {
        plan == .plus ? Color.plusBackgroundColor2 : Color.patronBackgroundColor
    }

    private var foregroundColor: Color {
        plan == .plus ? .plusButtonFilledTextColor : Color.patronButtonFilledTextColor
    }

    init(isLoading: Bool = false, plan: Plan) {
        self.isLoading = isLoading
        self.plan = plan
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

struct PlusGradientFilledButtonStyle: ButtonStyle {
    let isLoading: Bool
    let plan: Plan

    private var background: any View {
        plan == .plus ? Color.plusGradient : Color.patronBackgroundColor
    }

    private var foregroundColor: Color {
        plan == .plus ? .plusButtonFilledTextColor : Color.patronButtonFilledTextColor
    }

    init(isLoading: Bool = false, plan: Plan) {
        self.isLoading = isLoading
        self.plan = plan
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
    let plan: Plan

    private var foregroundColor: Color {
        plan == .plus ? Color.plusGradientColor1 : Color.patronGradientColor1
    }

    private var overlay: LinearGradient {
        plan == .plus ? Color.plusGradient : Color.patronGradient
    }

    private var selectedImageName: String {
        plan == .plus ? "icon-plus-button-selected" : "icon-patron-button-selected"
    }

    init(isSelectable: Bool = false, plan: Plan, isSelected: Bool = true) {
        self.isSelectable = isSelectable
        self.plan = plan
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding()

            // Overlay the gradient, or just set the color if not selected
            .foregroundColor(isSelected ? foregroundColor : Color.plusButtonUnselectedColor)
            .gradientOverlay(isSelected ? overlay : nil)

            // Stroke Overlay + Image if needed
            .overlay(
                ZStack {
                    if isSelected {
                        // Only show the image if we're selectable
                        if isSelectable {
                            HStack {
                                Spacer()
                                Image(selectedImageName).padding(.trailing)
                            }
                        }

                        RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius).stroke(overlay, lineWidth: ViewConstants.buttonStrokeWidth)
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
    let plan: Plan
    let isSelected: Bool

    private var color: LinearGradient {
        plan == .plus ? Color.plusGradient : Color.patronGradient
    }

    init(_ text: String, plan: Plan, isSelected: Bool = true) {
        self.text = text
        self.plan = plan
        self.isSelected = isSelected
    }

    var body: some View {
        Text(L10n.freeTrialDurationFreeTrial(text.localizedUppercase))
            .font(size: 12, style: .caption, weight: .semibold, maxSizeCategory: .extraExtraLarge)
            .multilineTextAlignment(.center)
            .padding([.top, .bottom], 4)
            .padding([.leading, .trailing], 13)
            .background(
                color.cornerRadius(4)
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

    static let patronGradient = LinearGradient(stops: [
        Gradient.Stop(color: .patronGradientColor1, location: 1)
    ], startPoint: .topLeading, endPoint: .topTrailing)

    static let plusGradientColor1 = Color(hex: "FED745")
    static let plusGradientColor2 = Color(hex: "FEB525")

    static let patronGradientColor1 = Color(hex: "AFA2FA")

    static let plusButtonUnselectedColor = Color.white
    static let plusButtonFilledTextColor = Color.black
    static let patronButtonFilledTextColor = Color.white

    static let patronBackgroundColor = Color(hex: "6046F5")

    static let plusBackgroundColor = Color(hex: "121212")
    static let plusLeftCircleColor = Color(hex: "ffd845")
    static let plusRightCircleColor = Color(hex: "ffb626")
    static let plusBackgroundColor2 = Color(hex: "FFD846")
}
