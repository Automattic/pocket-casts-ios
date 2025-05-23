import SwiftUI

struct KidsProfileSubmitScreen: View {
    @ObservedObject var viewModel: KidsProfileSheetViewModel

    @FocusState private var isFocused: Bool

    var theme: Theme

    var body: some View {
        VStack {
            Text(L10n.kidsProfileSubmitFeedbackTitle)
                .font(size: Constants.titleSize, style: .body, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText01)
                .padding(.leading, Constants.buttonHPadding)
                .padding(.trailing, Constants.buttonHPadding)
                .padding(.bottom, Constants.vPadding)

            TextEditor(text: $viewModel.textToSend)
                .themedTextField()
                .foregroundStyle(theme.secondaryText02)
                .focused($isFocused)
                .frame(minHeight: Constants.textEditorMinHeight, maxHeight: Constants.textEditorMaxHeight)
                .padding(.bottom, Constants.vPadding)

            sendButton
        }
        .padding(Constants.contentinset)
        .onAppear {
            isFocused = true
            Analytics.track(.kidsProfileFeedbackFormSeen)
        }
    }

    private var sendButton: some View {
        Button(action: viewModel.submitFeedback) {
            Text(L10n.kidsProfileSubmitFeedbackSendButton)
        }
        .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
        .frame(height: Constants.buttonHeight)
        .disabled(!viewModel.canSendFeedback)
        .opacity(viewModel.buttonOpacity)
    }

    enum Constants {
        static let buttonHeight = 56.0

        static let titleSize = 18.0
        static let textSize = 14.0

        static let vPadding = 16.0

        static let buttonHPadding = 40.0

        static let textEditorMinHeight = 75.0
        static let textEditorMaxHeight = 200.0

        static let contentinset = EdgeInsets(top: 63.0,
                                             leading: 20.0,
                                             bottom: 20.0,
                                             trailing: 20.0)
    }
}

#Preview {
    KidsProfileSubmitScreen(viewModel: KidsProfileSheetViewModel(),
                            theme: Theme(previewTheme: .light))
}
