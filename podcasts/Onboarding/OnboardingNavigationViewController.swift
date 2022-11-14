import UIKit

class OnboardingNavigationViewController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        updateNavigationBarStyle(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarStyle(animated: true)
    }

    private func updateNavigationBarStyle(animated: Bool) {
        guard let navController = navigationController else { return }

        let iconColor = AppTheme.colorForStyle(.primaryInteractive01)

        let navigationBar = navController.navigationBar
        navigationBar.backIndicatorImage = UIImage(named: "nav-back")?.tintedImage(iconColor)
        navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav-back")?.tintedImage(iconColor)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .red
        appearance.shadowColor = nil

        let applyAppearance = {
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.tintColor = iconColor
        }

        guard animated else {
            applyAppearance()
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime, animations: applyAppearance)
    }
}
