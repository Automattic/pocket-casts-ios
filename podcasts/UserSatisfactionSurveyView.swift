import SwiftUI
import StoreKit

struct UserSatisfactionSurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: Theme

    var presentSupportView: (() -> Void)?

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
                    surveyResponseButton(emoji: "😔", text: L10n.userSatisfactionSurveyNoResponse, action: handleNotReallyResponse)
                }

                VStack(spacing: 12) {
                    surveyResponseButton(emoji: "🥰", text: L10n.userSatisfactionSurveyYesResponse, action: handleYesResponse)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 32)
        .padding(.bottom, 32)
        .background(theme.primaryUi01)
    }

    private func handleYesResponse() {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: windowScene)
            Settings.addReviewRequested()
            Analytics.track(.appStoreReviewRequested, properties: ["source": AnalyticsSource.userSatisfactionSurvey])
        }
        dismiss()
    }

    private func handleNotReallyResponse() {
        presentSupportView?()
    }

    @ViewBuilder
    private func surveyResponseButton(emoji: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 68))

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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserSatisfactionSurveyView()
}
