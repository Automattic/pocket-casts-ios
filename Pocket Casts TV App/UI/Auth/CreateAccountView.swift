import SwiftUI

struct CreateAccountView: View {

    enum Layout {
        static let gridSize = CGFloat(272)
        static let qrSize = CGFloat(240)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 32) {
                Spacer()
                Image(ImageResource.pcLogo)
                Text(L10n.tvCreateAccountTitle)
                    .font(.title)
                Text(L10n.tvCreateAccountSubtitle)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                QRCodeView()
                Spacer()
                Text(L10n.tvCreateAccountComeBack)
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                NavigationLink(value: WelcomeView.Destination.signIn) {
                    Text(L10n.tvWelcomeSignIn)
                }
            }
        }
    }
}

#Preview {
    CreateAccountView()
        .environment(AppCoordinator())
}
