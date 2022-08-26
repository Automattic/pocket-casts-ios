import Foundation
import PocketCastsDataModel

class SupportUtils {
    private var loadingAlert: ShiftyLoadingAlert?

    /// ZIPs the users SQLite database and shows a share dialog for them to share it with us
    func exportDatabase(from controller: UIViewController, completion: @escaping () -> Void) {
        loadingAlert = ShiftyLoadingAlert(title: "Exporting Database")
        loadingAlert?.showAlert(controller, hasProgress: false, completion: {
            DataManager.sharedManager.exportDatabase { [weak self] url in
                self?.loadingAlert?.hideAlert(false)
                self?.loadingAlert = nil

                guard let url = url else {
                    SJUIUtils.showAlert(title: "Export Failed", message: "Could not export database.", from: controller)
                    completion()
                    return
                }

                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { _, _, _, _ in
                    completion()
                }
                controller.present(activityViewController, animated: true, completion: nil)
            }
        })
    }
}
