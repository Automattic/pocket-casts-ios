import SwiftUI
import PocketCastsServer
import PocketCastsUtils
import UIKit

class DeviceApproveViewModel: ObservableObject {

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

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
}

struct DeviceApproveView: View {

    @EnvironmentObject var theme: Theme

    @Environment(\.dismiss) var dismiss

    @State private var userCode: String

    @StateObject private var model: DeviceApproveViewModel

    @State private var showFailureAlert: Bool = false

    @State private var showSuccessAlert: Bool = false

    init(userCode: String?, model: DeviceApproveViewModel) {
        _userCode = State(initialValue: userCode ?? "")
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
                .frame(height: 100)
            logos
            title
            description
            if model.isUserLoggedIn {
                accountCard
                codeField
            }
            Spacer()
            actionButton
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .padding()
        .onAppear() {
            Analytics.track(.deviceApproveShown)
        }
        .alert(L10n.deviceApproveExpiredAlertTitle, isPresented: $showFailureAlert) {
            Button(L10n.ok, role: .cancel) {
                dismiss()
            }
        } message: {
            Text(L10n.deviceApproveExpiredAlertMessage)
        }
        .alert(L10n.deviceApproveSuccessAlertTitle, isPresented: $showSuccessAlert) {
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
            .onChange(of: userCode) { newValue in
                if newValue.count > 6 {
                    userCode = String(newValue.prefix(6))
                }
            }
    }

    private var actionButton: some View {
        Button {
            if model.isUserLoggedIn {
                Task {
                    Analytics.track(.deviceApproveConnectTapped)
                    let result = try? await AuthenticationHelper.deviceApprove(userCode: userCode, approve: true)
                    if result?.success == true {
                        Analytics.track(.deviceApproveSuccessful)
                        showSuccessAlert = true
                    } else {
                        Analytics.track(.deviceApproveFailed)
                        showFailureAlert = true
                    }
                }
            } else {
                Analytics.track(.deviceSetupAccountTapped)
                model.presentAccountFlow()
            }
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
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.primaryUi01)
                .frame(width: 32, height: 32)
                .background(theme.primaryInteractive01)
                .clipShape(Circle())
        }
        .accessibilityLabel(L10n.close)
        .padding(.top, 16)
        .padding(.trailing, 16)
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
        .environmentObject(Theme(previewTheme: .light))
}
