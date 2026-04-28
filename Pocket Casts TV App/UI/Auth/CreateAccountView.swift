import SwiftUI

@Observable
class CreateAccountViewModel {

    var codes: [String] = ["J", "M", "R", "S", "3", "W"]
}

struct CreateAccountView: View {
    @Environment(AppCoordinator.self) var coordinator

    @State private var model = SignInViewModel()

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
                qrCode
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

    var qrCode: some View {
        ZStack {
            Image(ImageResource.qrCode)
                .resizable()
                .frame(width: Layout.qrSize, height: Layout.qrSize)
        }
        .padding()
        .background(.white)
    }
}

#Preview {
    CreateAccountView()
        .environment(AppCoordinator())
}
