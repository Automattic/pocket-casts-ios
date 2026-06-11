import SwiftUI
import PocketCastsServer

class DeviceApproveViewModel: ObservableObject {

    var isUserLoggedIn: Bool {
        return SyncManager.isUserLoggedIn()
    }

    var email: String {
        return ServerSettings.syncingEmail() ?? ""
    }
}

struct DeviceApproveView: View {

    @EnvironmentObject var theme: Theme

    @Environment(\.dismiss) var dismiss

    @State private var userCode: String

    @StateObject private var model = DeviceApproveViewModel()

    init(userCode: String?) {
        _userCode = State(initialValue: userCode ?? "")
    }

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
                .frame(height: 100)
            HStack {
                Spacer()
                CircleLogo(name: "smallPCLogo", size: CGSize(width: 24, height: 24))
                Image("more")
                    .renderingMode(.template)
                    .foregroundStyle(theme.primaryUi05)
                CircleLogo(name: "appleTVLogo", size: CGSize(width: 40, height: 20))
                Spacer()
            }
            Text(L10n.deviceApproveTitle)
                .font(size: 22, style: .headline, weight: .bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText01)
            Text(L10n.deviceApproveDescription)
                .font(size: 15, style: .caption, weight: .regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.primaryText02)
            HStack(alignment: .center, spacing: 16) {
                if model.isUserLoggedIn {
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
                } else {
                    Text(L10n.deviceApproveLoginRequired)
                        .font(size: 15, style: .caption, weight: .regular)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(theme.primaryText02)
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
            if model.isUserLoggedIn {
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
            Spacer()
            Button {
                if model.isUserLoggedIn {
                    Task {
                        let result = try await AuthenticationHelper.deviceApprove(userCode: userCode, approve: true)
                        if result.success {
                            dismiss()
                        } else {
                        }
                    }
                } else {
                    dismiss()
                }
            } label: {
                Text(model.isUserLoggedIn ? L10n.deviceApproveConnectButton : L10n.close)
                    .textStyle(RoundedButton())
            }
        }
        .padding()
    }
}

struct CircleLogo: View {

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
    DeviceApproveView(userCode: "12345")
        .environmentObject(Theme(previewTheme: .light))
}
