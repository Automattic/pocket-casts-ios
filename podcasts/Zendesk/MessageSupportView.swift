import Combine
import SwiftUI

struct MessageSupportView: View {
    /// Dismiss Action for UIKit interfaces
    let dismiss: (() -> Void)?
    @ObservedObject private var viewModel: MessageSupportViewModel
    @EnvironmentObject var theme: Theme

    init(viewModel: MessageSupportViewModel, dismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.dismiss = dismiss
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                fieldGroup(label: L10n.supportNameIndicator) {
                    TextField(L10n.supportNamePlaceholder, text: $viewModel.requesterName)
                        .requiredStyle(viewModel.requesterNameErrored)
                }

                fieldGroup(label: L10n.supportEmailIndicator) {
                    TextField(L10n.supportEmailPlaceholder, text: $viewModel.requesterEmail)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(viewModel.isUserSignedIn)
                        .requiredStyle(viewModel.requesterEmailErrored)
                }

                fieldGroup(label: L10n.supportCommentIndicator) {
                    TextEditor(text: $viewModel.comment)
                        .scrollContentBackground(.hidden)
                        .colorScheme(Theme.isDarkTheme() ? .dark : .light)
                        .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
                        .padding(6)
                        .background(ThemeColor.primaryUi02(for: theme.activeTheme).color.cornerRadius(ViewConstants.cornerRadius))
                        .required(viewModel.commentErrored)
                        .frame(minHeight: 80)
                        .layoutPriority(1)
                }

                ThemedDivider()
                    .background(ThemeColor.primaryUi05(for: theme.activeTheme).color)
                NavigationLink(destination: viewModel.attachedLogsView) {
                    HStack {
                        Text(L10n.supportTitleAttachedLogs)
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                    .padding(.top, 5)
                }
            }
            .padding(20)
            .applyDefaultThemeOptions(backgroundOverride: .primaryUi04)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                        .disabled(viewModel.isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    submitButton
                        .disabled(!viewModel.isValid)
                }
            })
        }
        .accentColor(ThemeColor.secondaryIcon01(for: theme.activeTheme).color)
        .activityIndicator(isShowing: $viewModel.isWorking, message: L10n.supportWorking)
        .alert(item: $viewModel.completion) { completion in
            switch completion {
            case .success:
                return Alert(title: Text(L10n.supportThankyou), message: Text(L10n.supportThankyouMessage), dismissButton: .default(Text(L10n.supportOK), action: {
                    viewModel.completion = nil
                    dismiss?()
                }))
            case .failure(let error):
                switch error {
                case MessageSupportViewModel.MessageSupportFailure.watchLogMissing:
                    return Alert(title: Text(L10n.supportWatchHelpTitle), message: Text(L10n.supportWatchHelpMessage), primaryButton: .default(Text(L10n.supportWatchHelpOpenedApp)) { viewModel.submitRequest() }, secondaryButton: .default(Text(L10n.supportWatchHelpSendWithoutLog)) { viewModel.submitRequest(ignoreUnavailableWatchLogs: true) })
                default:
                    return Alert(title: Text(L10n.supportErrorTitle), message: Text(L10n.supportErrorMsg), dismissButton: .default(Text(L10n.supportOK), action: {
                        viewModel.completion = nil
                    }))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
            content()
        }
    }

    @ViewBuilder
    private var cancelButton: some View {
        if #available(iOS 26.0, *) {
            Button(role: .cancel) {
                dismiss?()
            }
        } else {
            Button(L10n.supportCancel, role: .cancel) {
                dismiss?()
            }
            .navThemed()
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        if #available(iOS 26.0, *) {
            Button(L10n.supportSubmit, role: .confirm) {
                viewModel.submitRequest()
            }
        } else {
            Button(L10n.supportSubmit) {
                viewModel.submitRequest()
            }
            .navThemed()
        }
    }
}

// MARK: Previews

struct MessageSupportView_Previews: PreviewProvider {
    struct PreviewConfig: ZDConfig {
        let apiKey = "1234567"
        let baseURL = "https://example.com"
        let newBaseURL = "https://example.com"
        let subject = "For Previews"
        let type: ZDType = .feedback
    }

    static var previews: some View {
        MessageSupportView(viewModel: MessageSupportViewModel(config: PreviewConfig(), isUserSignedIn: true))
            .environmentObject(Theme(previewTheme: .rosé))
    }
}
