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

    private let controlSpacing: CGFloat = 22

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text(L10n.supportNameIndicator)
                TextField(L10n.supportNamePlaceholder, text: $viewModel.requesterName)
                    .requiredStyle(viewModel.requesterNameErrored)
                    .padding(.bottom, controlSpacing)
                Text(L10n.supportEmailIndicator)
                TextField(L10n.supportEmailPlaceholder, text: $viewModel.requesterEmail)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .requiredStyle(viewModel.requesterEmailErrored)
                    .padding(.bottom, controlSpacing)
                Text(L10n.supportCommentIndicator)
                TextEditor(text: $viewModel.comment)
                    .themedTextField(hasErrored: viewModel.commentErrored)
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
            .padding()
            .applyDefaultThemeOptions(backgroundOverride: .primaryUi04)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.supportCancel) {
                        dismiss?()
                    }
                    .navThemed()
                    .disabled(viewModel.isWorking)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.supportSubmit) {
                        viewModel.submitRequest()
                    }
                    .navThemed()
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
            case .failure:
                return Alert(title: Text(L10n.supportErrorTitle), message: Text(L10n.supportErrorMsg), dismissButton: .default(Text(L10n.supportOK), action: {
                    viewModel.completion = nil
                }))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: Previews

struct MessageSupportView_Previews: PreviewProvider {
    struct PreviewConfig: ZDConfig {
        let apiKey = "1234567"
        let baseURL = "https://example.com"
        let subject = "For Previews"
        let isFeedback = true
    }

    static var previews: some View {
        MessageSupportView(viewModel: MessageSupportViewModel(config: PreviewConfig()))
            .environmentObject(Theme(previewTheme: .rosé))
    }
}
