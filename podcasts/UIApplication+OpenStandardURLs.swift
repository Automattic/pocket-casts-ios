import UIKit

extension UIApplication {

    func openNotificationSettings() {
        guard let appSettings = URL(string: UIApplication.openNotificationSettingsURLString), UIApplication.shared.canOpenURL(appSettings) else {
            return
        }
        UIApplication.shared.open(appSettings)
    }
}
