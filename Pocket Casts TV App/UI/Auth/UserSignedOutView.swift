import SwiftUI
import PocketCastsServer

struct UserSignedOutView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 24) {
            Text(L10n.tvAccountSignedOutAlertTitle)
                .font(.title)
                .foregroundColor(Color.pcTextPrimary)
            Text(L10n.tvAccountSignedOutAlertMessage)
                .font(.headline)
                .foregroundColor(Color.pcTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            Button(L10n.tvWelcomeLogIn) {
                coordinator.logout()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pcBackgroundSurface)
        .ignoresSafeArea()
    }
}

#Preview {
    UserSignedOutView()
        .environment(AppCoordinator())
}
