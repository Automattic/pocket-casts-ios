import Foundation
import SwiftUI

class OnboardingHostingViewController<Content>: UIHostingController<Content> where Content: View {
    var navBarIsHidden: Bool = false
    var iconTintColor: UIColor = AppTheme.colorForStyle(.primaryIcon01)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBarStyle(animated: false)

        navigationController?.navigationBar.isHidden = navBarIsHidden
        navigationController?.navigationBar.tintColor = iconTintColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavigationBarStyle(animated: false)


        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = iconTintColor

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)
    }

    @objc func themeDidChange() {
        updateNavigationBarStyle(animated: false)
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
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        // Update the back icon
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: "arrow.left")?.applyingSymbolConfiguration(config)

        barAppearance.backIndicatorImage = image
        barAppearance.backIndicatorTransitionMaskImage = image
    }
}

class OnboardingNavigationViewController: UINavigationController {
    // just for referencing in the appearance above
}
