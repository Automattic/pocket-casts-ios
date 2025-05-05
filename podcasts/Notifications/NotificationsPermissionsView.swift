import SwiftUI

class NotificationsPermissionsViewModel: ObservableObject {

    func requestPermissions() {

    }

    static func makeController() -> UIViewController {
        let viewModel = NotificationsPermissionsViewModel()

        let view = NotificationsPermissionsView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view.setupDefaultEnvironment())

        return  controller
    }
}

struct NotificationsPermissionsView: View {

    @EnvironmentObject var theme: Theme

    @StateObject var viewModel: NotificationsPermissionsViewModel = NotificationsPermissionsViewModel()

    var body: some View {
        VStack {
            Image("notifications_permissions_banner")
            Text("Stay up to date!")
                .textStyle(PrimaryText())
                .font(.largeTitle.bold())
            Text("Notifications are the best way to keep track of new episodes, get recommendations of new shows and tips about Pocket Casts.")
                .textStyle(SecondaryText())
                .font(.body)
            Spacer()
            Button(action: {
                viewModel.requestPermissions()
            }) {
                Text("Allow Notifications")
                .textStyle(RoundedButton())
            }
        }
    }
}

struct NotificationsPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsPermissionsView()
            .environmentObject(Theme(previewTheme: .light))
    }
}
