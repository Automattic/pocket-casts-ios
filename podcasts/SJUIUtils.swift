import Foundation

class SJUIUtils {
    class func showAlert(title: String, message: String?, from: UIViewController?, completion: (() -> Void)? = nil) {
        guard let controller = from else { return }

        let alert = createDialog(title: title, message: message)
        if Thread.isMainThread {
            controller.present(alert, animated: true, completion: completion)
        } else {
            DispatchQueue.main.async {
                controller.present(alert, animated: true, completion: completion)
            }
        }
    }

    class func navController(for controller: UIViewController, navStyle: ThemeStyle = .secondaryUi01, titleStyle: ThemeStyle = .secondaryText01, iconStyle: ThemeStyle = .primaryIcon01, themeOverride: Theme.ThemeType? = nil) -> PCNavigationController {
        PCNavigationController(rootViewController: controller, navStyle: navStyle, titleStyle: titleStyle, iconStyle: iconStyle, themeOverride: themeOverride)
    }

    class func popupNavController(for controller: UIViewController, navStyle: ThemeStyle = .secondaryUi01, titleStyle: ThemeStyle = .secondaryText01, iconStyle: ThemeStyle = .primaryIcon01, themeOverride: Theme.ThemeType? = nil) -> PCNavigationController {
        let navController = PCNavigationController(rootViewController: controller, navStyle: navStyle, titleStyle: titleStyle, iconStyle: iconStyle, themeOverride: themeOverride)
        navController.modalPresentationStyle = .fullScreen
        return navController
    }

    private class func createDialog(title: String, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.ok, style: .default, handler: nil)
        alert.addAction(okAction)

        return alert
    }
}
