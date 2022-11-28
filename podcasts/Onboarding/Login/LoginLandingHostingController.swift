import Foundation
import SwiftUI

class LoginLandingHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel as? LoginCoordinator else { return }

        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalForBackgroundImageName
        imageView.accessibilityLabel = L10n.setupAccount
        navigationItem.titleView = imageView

        if navigationController?.viewControllers.first == self {
            let dismissItem = UIBarButtonItem(title: L10n.eoyNotNow, style: .plain, target: viewModel, action: #selector(viewModel.dismissTapped))
            dismissItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.font(with: .body, weight: .medium),
                                                NSAttributedString.Key.foregroundColor: iconTintColor], for: .normal)
            navigationItem.rightBarButtonItem = dismissItem
        }

        navigationController?.navigationBar.isHidden = false
    }
}
