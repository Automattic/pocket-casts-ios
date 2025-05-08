import SwiftUI

class NotificationsPermissionsViewModel: ObservableObject {

    func setupPermissions() async {
        let coordinator = NotificationsCoordinator.shared
        await coordinator.requestAndSetupInitialPermissions()
    }

    static func makeController() -> UIViewController {
        let viewModel = NotificationsPermissionsViewModel()

        let view = NotificationsPermissionsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        return  controller
    }
}

struct NotificationsPermissionsView: View {

    @Environment(\.dismiss) private var dismissAction

    @EnvironmentObject var theme: Theme

    @StateObject var viewModel: NotificationsPermissionsViewModel = NotificationsPermissionsViewModel()

    var body: some View {
        VStack {
            Button(action: {
                Analytics.track(.notificationsPermissionsNotNowTapped)
                dismissAction()
            }) {
                HStack {
                    Spacer()
                    Text(L10n.eoyNotNow)
                        .foregroundStyle(theme.primaryInteractive01)
                        .font(.body.weight(.medium))
                }
            }
            Image("notifications_permissions_banner")
            Spacer().frame(height: 24)
            Text(L10n.notificationsPermissionsTitle)
                .textStyle(PrimaryText())
                .font(.largeTitle.bold())
            Spacer().frame(height: 16)
            Text(L10n.notificationsPermissionsBody)
                .textStyle(SecondaryText())
                .font(.body)
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: {
                Analytics.track(.notificationsPermissionsAllowTapped)
                Task {
                    await viewModel.setupPermissions()
                    dismissAction()
                }
            }) {
                Text(L10n.notificationsPermissionsAction)
                .textStyle(RoundedButton())
            }
        }
        .padding()
        .background(theme.primaryUi01)
        .onAppear() {
            Analytics.track(.notificationsPermissionsShown)
        }
    }
}

struct NotificationsPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsPermissionsView()
            .environmentObject(Theme(previewTheme: .light))
    }
}
