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
        guard animated else {
            apply()
            return
        }

        UIView.animate(withDuration: Constants.Animation.defaultAnimationTime) {
            self.apply()
        }
    }

    private func apply() {
        let instances = [OnboardingNavigationViewController.self]

        let barAppearance =
            UINavigationBar.appearance(whenContainedInInstancesOf: instances)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance

        // Update the back icon
        let iconColor = AppTheme.colorForStyle(.primaryInteractive01)
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: "arrow.left")?.applyingSymbolConfiguration(config)

        barAppearance.backIndicatorImage = image
        barAppearance.backIndicatorTransitionMaskImage = image
        barAppearance.tintColor = iconColor
    }
}
