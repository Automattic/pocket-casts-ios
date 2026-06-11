import SwiftUI

struct DeviceApproveView: View {

    @EnvironmentObject var theme: Theme

    @Environment(\.dismiss) var dismiss

    @State private var userCode: String

    init(userCode: String?) {
        _userCode = State(initialValue: userCode ?? "")
    }
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
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
            TextField(L10n.deviceApproveCodePlaceholder, text: $userCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .padding()
                .foregroundStyle(theme.primaryText02)
                .background(theme.primaryUi02)
                .cornerRadius(12)
                .padding(.horizontal)
            Button {
                Task {
                    let result = try await AuthenticationHelper.deviceApprove(userCode: userCode, approve: true)
                    if result.success {
                        dismiss()
                    } else {

                    }
                }
            } label: {
                Text(L10n.deviceApproveConnectButton)
                    .textStyle(RoundedButton())
            }
            Spacer()
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
        .environmentObject(Theme(previewTheme: .dark))
}
