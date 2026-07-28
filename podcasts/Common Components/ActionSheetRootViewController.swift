
import UIKit

class ActionSheetRootViewController: UIViewController {
    var overrideStatusBarStyle = AppTheme.defaultStatusBarStyle()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        overrideStatusBarStyle
    }
}
