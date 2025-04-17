import UIKit

extension UIApplication {

    func openNotificationSettings() {
        var appNotificationSettings = UIApplication.openSettingsURLString

        if #available(iOS 16, *) {
            appNotificationSettings = UIApplication.openNotificationSettingsURLString
        } else if #available(iOS 15.4, *) {
            appNotificationSettings = UIApplicationOpenNotificationSettingsURLString
        }
        guard let appSettings = URL(string: appNotificationSettings), UIApplication.shared.canOpenURL(appSettings) else {
            return
        }
        UIApplication.shared.open(appSettings)
    }
}
