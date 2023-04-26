import SwiftUI

// MARK: - Buttons
struct SocialButtonStyle: ButtonStyle {
    let imageName: String

    let textColor: Color = AppTheme.colorForStyle(.primaryText01).color
    let strokeColor: Color = AppTheme.colorForStyle(.primaryInteractive03).color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding()

            .foregroundColor(textColor)
            .overlay(
                // Image Overlay
                ZStack {
                    HStack {
                        Image(imageName)
                            .padding(.leading)
                        Spacer()
                    }

                    RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 3))
                }
            )
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .contentShape(Rectangle())
            .applyButtonEffect(isPressed: configuration.isPressed)
    }
}
