import UIKit

class OnboardingNavigationViewController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func themeDidChange() {
        updateNavigationBarStyle(animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateNavigationBarStyle(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarStyle(animated: true)
    }

    private func updateNavigationBarStyle(animated: Bool) {
        let iconColor = AppTheme.colorForStyle(.primaryInteractive01)
        let backIcon = UIImage(named: "nav-back")?.tintedImage(iconColor)

        navigationBar.backIndicatorImage = backIcon
        navigationBar.backIndicatorTransitionMaskImage = backIcon

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil

        let applyAppearance = {
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = appearance
            self.navigationBar.tintColor = iconColor
        }

        guard animated else {
            applyAppearance()
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime,
                       animations: applyAppearance)
    }
}
