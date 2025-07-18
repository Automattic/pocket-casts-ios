import SwiftUI
import Lottie

struct UserSatisfactionSurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: Theme

    enum Response {
        case yes
        case no
    }

    var handleResponse: (Response) -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text(L10n.userSatisfactionSurveyTitle)
                    .font(.headline)
                    .foregroundColor(theme.primaryText01)

                Text(L10n.userSatisfactionSurveySubtitle)
                    .font(.callout)
                    .foregroundColor(theme.primaryText02)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 24) {
                VStack(spacing: 12) {
                    surveyResponseButton(emoji: "pensive", text: L10n.userSatisfactionSurveyNoResponse) {
                        handleResponse(.no)
                        dismiss()
                    }
                }

                VStack(spacing: 12) {
                    surveyResponseButton(emoji: "heart-eyes", text: L10n.userSatisfactionSurveyYesResponse) {
                        handleResponse(.yes)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 32)
        .padding(.bottom, 32)
        .background(theme.primaryUi01)
    }

    @ViewBuilder
    private func surveyResponseButton(emoji: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                LottieView(animation: .named(emoji, animationCache: nil))
                    .looping()
                    .frame(height: 72)

                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText01)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .if(UIAccessibility.buttonShapesEnabled) {
                $0.background(theme.primaryUi05)
            }
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    UserSatisfactionSurveyView(handleResponse: { _ in })
}
