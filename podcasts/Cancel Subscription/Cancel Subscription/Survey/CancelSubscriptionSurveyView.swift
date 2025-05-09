import SwiftUI

struct CancelSubscriptionSurveyView: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: CancelSubscriptionSurveyViewModel

    @FocusState private var isFocused: Bool

    init(viewModel: CancelSubscriptionSurveyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        header
                            .padding(.horizontal, 16.0)
                            .padding(.bottom, 16.0)
                        ForEach(CancelSubscriptionSurveyViewModel.Reason.allCases, id: \.id) { reason in
                            CancelSubscriptionSurveyRow(reason: reason, selected: reason == viewModel.selectedReason) { reason in
                                if viewModel.isLoading {
                                    return
                                }
                                viewModel.selectedReason = reason
                                isFocused = reason == .other
                            }
                        }
                        if viewModel.selectedReason == .other {
                            TextEditor(text: $viewModel.additionalText)
                                .font(size: 15.0, style: .body, weight: .regular, maxSizeCategory: .extraExtraExtraLarge)
                                .themedTextField(style: .primaryUi01)
                                .foregroundStyle(theme.primaryText01)
                                .focused($isFocused)
                                .disabled(viewModel.isLoading)
                                .frame(height: 80.0)
                                .padding(.horizontal, 18.0)
                        }
                        Spacer()
                            .frame(minHeight: 105)
                            .id("bottom")
                    }
                    .id("content")
                }
                .onChange(of: isFocused) { focused in
                    withAnimation {
                        scrollProxy.scrollTo(focused ? "bottom" : "content", anchor: focused ? .bottom : .top)
                    }
                }
                .padding(.top, 48)
                .modify {
                    if #available(iOS 16.4, *) {
                        $0.scrollBounceBehavior(.basedOnSize)
                    }
                }
            }

            VStack {
                HStack {
                    Button {
                        viewModel.dismiss()
                    } label: {
                        Image("close")
                            .renderingMode(.template)
                            .foregroundStyle(theme.primaryField03Active)
                    }
                    .frame(width: 32.0, height: 32.0)
                    .padding(8.0)
                    Spacer()
                }
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryUi01.opacity(0), theme.primaryUi01],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 16)
                button
                    .frame(height: 88.0)
            }
        }
        .background(
            AppTheme.color(for: .primaryUi01, theme: theme)
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        VStack(spacing: 8.0) {
            Text(L10n.cancelSubscriptionSurveyTitle)
                .font(style: .title, weight: .bold, maxSizeCategory: .extraExtraExtraLarge)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(theme.primaryText01)
            Text(L10n.cancelSubscriptionSurveyDescription)
                .font(size: 15.0, style: .body, weight: .regular, maxSizeCategory: .extraExtraExtraLarge)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(theme.primaryText02)
        }
    }

    private var button: some View {
        ZStack {
            Rectangle()
                .fill(theme.primaryUi01)
            Button {
                viewModel.sendFeedback()
                isFocused = false
            } label: {
                Text(L10n.cancelSubscriptionSurveySubmitFeedback)
            }
            .buttonStyle(BasicButtonStyle(textColor: theme.primaryInteractive02, backgroundColor: theme.primaryInteractive01))
            .disabled(!viewModel.canSendFeedback)
            .frame(height: 56)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .opacity(viewModel.canSendFeedback ? 1.0 : 0.6)
            .overlay {
                if viewModel.isLoading {
                    loadingButton
                }
            }
        }
    }

    private var loadingButton: some View {
        ZStack {
            Rectangle()
                .overlay(theme.primaryInteractive01)
                .cornerRadius(ViewConstants.buttonCornerRadius)
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: theme.primaryInteractive02)
                )
        }
        .frame(height: 56.0)
        .padding(.horizontal, 16.0)
        .padding(.vertical, 16)
    }
}

#Preview {
    CancelSubscriptionSurveyView(viewModel: CancelSubscriptionSurveyViewModel(navigationController: nil))
        .environmentObject(Theme.sharedTheme)
}
