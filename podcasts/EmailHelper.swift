import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import UIKit

class EmailHelper: NSObject {
    func presentSupportDialog(_ source: UIViewController, type: ZDType) {
        DispatchQueue.main.async {
            let config = SupportConfig(type: type)
            let viewModel = PCMessageSupportViewModel(config: config)
            let supportView = MessageSupportView(viewModel: viewModel) {
                source.dismiss(animated: true, completion: nil)
            }
            .environmentObject(Theme.sharedTheme)

            let hostingController = PCHostingController(rootView: supportView)
            hostingController.isModalInPresentation = true
            source.present(hostingController, animated: true, completion: nil)
        }
    }
}
