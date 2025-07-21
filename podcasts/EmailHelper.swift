import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import UIKit

class EmailHelper: NSObject {
    func presentSupportDialog(_ source: UIViewController, type: ZDType) {
        DispatchQueue.main.async {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.openingNonOverlayableWindow)
            let config = SupportConfig(type: type)
            let viewModel = PCMessageSupportViewModel(config: config)
            let supportView = MessageSupportView(viewModel: viewModel) {
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.closedNonOverlayableWindow)
                source.dismiss(animated: true, completion: nil)
            }
            .environmentObject(Theme.sharedTheme)

            let hostingController = PCHostingController(rootView: supportView)
            hostingController.isModalInPresentation = true
            source.present(hostingController, animated: true, completion: nil)
        }
    }
}
