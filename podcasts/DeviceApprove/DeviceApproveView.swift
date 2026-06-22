import SwiftUI
import PocketCastsServer
import PocketCastsUtils
import UIKit

@MainActor
class DeviceApproveViewModel: ObservableObject {

    @Published
    var showSuccessAlert: Bool = false

    @Published
    var showFailureAlert: Bool = false

    @Published
    var errorMessage: String = ""

    @Published
    var errorTitle: String = ""

    var isUserLoggedIn: Bool {
        return SyncManager.isUserLoggedIn()
    }

    var email: String {
        return ServerSettings.syncingEmail() ?? ""
    }

    func presentAccountFlow() {
        let controller = OnboardingFlow.shared.begin(flow: .deviceApproval, source: .deviceApproval, accountCreated: { created in
            FileLog.shared.addMessage("Account created:\(created)")
        })
        let baseVC = presentingViewController.presentedViewController ?? presentingViewController
        baseVC.present(controller, animated: true)
    }

    let presentingViewController: UIViewController

    func actionButtonTapped(userCode: String) {
        guard isUserLoggedIn else {
            Analytics.track(.deviceSetupAccountTapped)
            presentAccountFlow()
            return
        }
        Task {
            Analytics.track(.deviceApproveConnectTapped)
            do {
                let result = try await AuthenticationHelper.deviceApprove(userCode: userCode, approve: true)
                if result.success == true {
                    Analytics.track(.deviceApproveSuccessful)
                    showSuccessAlert = true
                } else {
                    Analytics.track(.deviceApproveFailed)
                    errorTitle = L10n.deviceApproveExpiredAlertTitle
                    errorMessage = L10n.deviceApproveExpiredAlertMessage
                    showFailureAlert = true
                }
            } catch let error as APIError {
                showFailureAlert = true
                if error == APIError.INVALID_GRANT {
                    errorTitle = L10n.deviceApproveExpiredAlertTitle
                    errorMessage = L10n.deviceApproveExpiredAlertMessage
                } else {
                    errorTitle = L10n.deviceApproveGenericErrorAlertTitle
                    errorMessage = L10n.pleaseTryAgainLater
                }
            }
        }
    }

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
}

struct DeviceApproveView: View {

    @EnvironmentObject var theme: Theme

    @Environment(\.dismiss) var dismiss

    @State private var userCode: String

    @StateObject private var model: DeviceApproveViewModel

    init(userCode: String?, model: DeviceApproveViewModel) {
        _userCode = State(initialValue: userCode ?? "")
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
                .frame(height: 100)
            logos
            VStack(spacing: 8) {
                title
                description
            }
            if model.isUserLoggedIn {
                accountCard
                codeField
            }
            Spacer()
            actionButton
        }
        .overlay(alignment: .topLeading) {
            closeButton
        }
        .padding()
        .onAppear() {
            Analytics.track(.deviceApproveShown)
        }
        .alert(model.errorTitle, isPresented: $model.showFailureAlert) {
            Button(L10n.ok, role: .cancel) {
                dismiss()
            }
        } message: {
            Text(model.errorMessage)
        }
        .alert(L10n.deviceApproveSuccessAlertTitle, isPresented: $model.showSuccessAlert) {
            Button(L10n.ok, role: .cancel) {
                dismiss()
            }
        } message: {
            Text(L10n.deviceApproveSuccessAlertMessage)
        }
    }

    private var logos: some View {
        HStack {
            Spacer()
            CircleLogo(name: "smallPCLogo", size: CGSize(width: 24, height: 24))
            Image("connectDots")
                .renderingMode(.template)
                .foregroundStyle(theme.primaryUi05)
            CircleLogo(name: "appleTVLogo", size: CGSize(width: 40, height: 20))
            Spacer()
        }
    }

    private var title: some View {
        Text(L10n.deviceApproveTitle)
            .font(size: 22, style: .headline, weight: .bold)
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.primaryText01)
    }

    private var description: some View {
        Text(model.isUserLoggedIn ? L10n.deviceApproveDescription : L10n.deviceApproveLoginRequired)
            .font(size: 15, style: .caption, weight: .regular)
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.primaryText02)
    }

    @ViewBuilder
    private var accountCard: some View {
        HStack(alignment: .center, spacing: 16) {
                ProfileImage(email: model.email)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(L10n.deviceApproveSigningInAs)
                        .font(size: 15, style: .caption, weight: .regular)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.primaryText02)
                    Text(model.email)
                        .font(size: 15, style: .caption, weight: .semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.primaryText01)
                }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.primaryUi02)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(theme.primaryUi05, lineWidth: 1)
        )
    }

    private var codeField: some View {
        TextField(L10n.deviceApproveCodePlaceholder, text: $userCode)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .padding()
            .foregroundStyle(theme.primaryText02)
            .background(theme.primaryUi02)
            .cornerRadius(12)
            .padding(.horizontal)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled(true)
            .onChange(of: userCode) { _, newValue in
                if newValue.count > 6 {
                    userCode = String(newValue.prefix(6))
                }
            }
            .onSubmit {
                model.actionButtonTapped(userCode: userCode)
            }
    }

    private var actionButton: some View {
        Button {
            model.actionButtonTapped(userCode: userCode)
        } label: {
            Text(model.isUserLoggedIn ? L10n.deviceApproveConnectButton : L10n.setupAccount)
                .textStyle(RoundedButton())
        }
    }

    private var closeButton: some View {
        Button() {
            Analytics.track(.deviceApproveDismissed)
            dismiss()
        } label: {
            Image("close")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 44, height: 44)
                .if(!isiOS26) { content in
                    content
                        .foregroundStyle(theme.primaryUi01)
                        .background(theme.primaryInteractive01)
                        .clipShape(Circle())
                }
                .if(isiOS26) { content in
                    content
                        .foregroundStyle(theme.primaryText01)
                }
        }
        .glassStyle()
        .accessibilityLabel(L10n.close)
        .padding(.top, 16)
        .padding(.leading, 16)
    }

    var isiOS26: Bool {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
    }
}

struct GlassButtonModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
        }
    }
}

extension View {
    func glassStyle()
    -> some View {
        modifier(GlassButtonModifier())
  }
}

private struct CircleLogo: View {

    let name: String
    let size: CGSize

    var body: some View {
        ZStack(alignment: .center) {
            Image(name)
                .resizable()
                .frame(width: size.width, height: size.height)
        }
        .frame(width: 86, height: 86)
        .background(
            LinearGradient(
            stops: [
            Gradient.Stop(color: Color(red: 0, green: 0.02, blue: 0.04), location: 0.00),
            Gradient.Stop(color: Color(red: 0.05, green: 0.29, blue: 0.44), location: 1.00),
            ],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: 1, y: 1)
        )
        )
        .cornerRadius(86)
    }
}

#Preview {
    DeviceApproveView(userCode: "12345", model: DeviceApproveViewModel(presentingViewController: UIViewController()))
        .environmentObject(Theme(previewTheme: .dark))
}
