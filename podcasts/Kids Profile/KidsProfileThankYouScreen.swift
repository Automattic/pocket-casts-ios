import SwiftUI

struct KidsProfileThankYouScreen: View {
    var viewModel: KidsProfileSheetViewModel
    var theme: Theme

    var body: some View {
        VStack {
            Image("kids-profile-view-face")
                .padding(.top, Constants.imageTopPadding)
                .padding(.bottom, Constants.smallBottomPadding)

            Text(L10n.kidsProfileThankyouTitle)
                .font(size: Constants.titleSize, style: .body, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText01)
                .padding(.bottom, Constants.smallBottomPadding)

            Text(L10n.kidsProfileThankyouText)
                .font(size: Constants.textSize, style: .body, weight: .medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText02)
                .padding(.leading, Constants.hPadding * 2.0)
                .padding(.trailing, Constants.hPadding * 2.0)

            sendButton
                .padding(EdgeInsets(top: Constants.vPadding, leading: Constants.hPadding, bottom: Constants.vPadding, trailing: Constants.hPadding))

            closeButton
                .padding(.leading, Constants.hPadding)
                .padding(.trailing, Constants.hPadding)
        }
    }

    private var sendButton: some View {
        Button(action: viewModel.sendFeedback) {
            Text(L10n.kidsProfileThankyouButtonSend)
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
        .frame(height: Constants.buttonHeight)
    }

    private var closeButton: some View {
        Button(action: viewModel.dismissScreen) {
            Text(L10n.kidsProfileThankyouButtonClose)
        }
        .buttonStyle(StrokeButton(textColor: theme.primaryInteractive01, backgroundColor: theme.primaryUi01, strokeColor: theme.primaryInteractive01))
        .frame(height: Constants.buttonHeight)
    }

    enum Constants {
        static let buttonHeight = 56.0

        static let hPadding = 20.0
        static let vPadding = 8.0

        static let imageTopPadding = 12.0

        static let smallBottomPadding = 4.0

        static let titleSize = 18.0
        static let textSize = 14.0
    }
}

#Preview {
    KidsProfileThankYouScreen(viewModel: KidsProfileSheetViewModel(),
                              theme: Theme(previewTheme: .light))
}
