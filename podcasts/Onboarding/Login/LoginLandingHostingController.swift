import Foundation
import SwiftUI

class LoginLandingHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    let coordinator: LoginCoordinator

    init(rootView: Content, coordinator: LoginCoordinator) {
        self.coordinator = coordinator
        super.init(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalForBackgroundImageName
        imageView.accessibilityLabel = L10n.setupAccount
        navigationItem.titleView = imageView

        if navigationController?.viewControllers.first == self {
            let dismissItem = UIBarButtonItem(title: L10n.eoyNotNow, style: .plain, target: coordinator, action: #selector(LoginCoordinator.dismissTapped))
            dismissItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.font(with: .body, weight: .medium),
                                                NSAttributedString.Key.foregroundColor: iconTintColor], for: .normal)
            navigationItem.rightBarButtonItem = dismissItem
        }

        navigationController?.navigationBar.isHidden = false
    }
}
