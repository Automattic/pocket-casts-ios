import SwiftUI

struct ProfileRefreshButton: View {
    @EnvironmentObject var theme: Theme
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 20

    let title: String
    let isAnimating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("profile-retry")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        isAnimating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: isAnimating
                    )

                Text(title)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(ProfileStrokeButtonStyle())
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ProfileStrokeButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(style: .subheadline, weight: .medium)
            .foregroundColor(theme.primaryText01)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: ViewConstants.buttonCornerRadius)
                    .stroke(theme.primaryUi05, lineWidth: ViewConstants.buttonStrokeWidth)
            )
            .applyButtonEffect(isPressed: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
