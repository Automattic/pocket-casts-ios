import SwiftUI
import PocketCastsServer

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
                    .foregroundColor(Color.pcTextPrimary)
                Text(L10n.tvCreateAccountSubtitle)
                    .font(.headline)
                    .foregroundStyle(Color.pcTextSecondary)
                Spacer()
                QRCodeView(url: ServerConstants.Urls.tvCreate)
                Spacer()
                Text(L10n.tvCreateAccountComeBack)
                    .font(.headline)
                    .foregroundStyle(Color.pcTextSecondary)
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
