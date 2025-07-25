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
                    surveyResponseButton(emoji: "pensive", text: L10n.userSatisfactionSurveyNoResponse, haptic: provideSadHaptic) {
                        handleResponse(.no)
                        dismiss()
                    }
                }

                VStack(spacing: 12) {
                    surveyResponseButton(emoji: "heart-eyes", text: L10n.userSatisfactionSurveyYesResponse, haptic: provideHappyHaptic) {
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
    private func surveyResponseButton(emoji: String, text: String, haptic: @escaping () -> Void, action: @escaping () -> Void) -> some View {
        PressableLottieButton(emoji: emoji, text: text, theme: theme, haptic: haptic, action: action)
    }

    private func provideHappyHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactFeedback.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
    }

    private func provideSadHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
            heavyFeedback.impactOccurred()
        }
    }
}

struct PressableLottieButton: View {
    let emoji: String
    let text: String
    let theme: Theme
    let haptic: () -> Void
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
            PressableLottieButtonStyle(
                animation: .named(emoji),
                haptic: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                replayOnPress: true
            )
        )
    }
}

#Preview {
    UserSatisfactionSurveyView(handleResponse: { _ in })
}
