import SwiftUI
import Lottie

struct UserSatisfactionSurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: Theme

    enum Response {
        case yes
        case no
    }

    var constantlyAnimating: Bool = false
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
        PressableLottieButton(emoji: emoji, text: text, theme: theme, constantlyAnimating: constantlyAnimating, action: action)
    }
}

struct PressableLottieButton: View {
    let emoji: String
    let text: String
    let theme: Theme
    let constantlyAnimating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(theme.primaryText01)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .if(UIAccessibility.buttonShapesEnabled) {
                    $0.background(theme.primaryUi05)
                }
                .cornerRadius(12)
        }
        .buttonStyle(
            PressableLottieButtonStyle { isPressed in
                AnyView(
                    LottieView(animation: .named(emoji, animationCache: nil))
                        .playbackMode(
                            constantlyAnimating
                            ? .playing(.toProgress(0.99, loopMode: .loop))
                            : (isPressed
                               ? .playing(.toProgress(0.99, loopMode: .loop))
                               : .paused)
                        )
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                        .frame(height: 72)
                )
            }
        )
    }
}

struct PressableLottieButtonStyle: ButtonStyle {
    let lottieView: (Bool) -> AnyView

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) {
            lottieView(configuration.isPressed)

            configuration.label
        }
    }
}

#Preview {
    UserSatisfactionSurveyView(handleResponse: { _ in })
}
