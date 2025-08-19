import SwiftUI

// MARK: - Buttons
struct SocialButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    let imageName: String

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .applyButtonFont()
            .frame(maxWidth: .infinity)
            .padding()

            .foregroundColor(theme.primaryText01)
            .overlay(
                // Image Overlay
                ZStack {
                    HStack {
                        Image(imageName)
                            .padding(.leading)
                        Spacer()
                    }

                    RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                        .stroke(theme.primaryInteractive03, style: StrokeStyle(lineWidth: 3))
                }
            )
            .cornerRadius(ViewConstants.buttonCornerRadius)
            .contentShape(Rectangle())
            .applyButtonEffect(isPressed: configuration.isPressed)
    }
}
