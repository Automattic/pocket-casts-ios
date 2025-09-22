import Foundation
import SwiftUI
import PocketCastsUtils

class LoginLandingHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel as? LoginCoordinator else { return }

        if !FeatureFlag.newOnboardingAccountCreation.enabled {
            let imageView = ThemeableImageView(frame: .zero)
            imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalForBackgroundImageName
            imageView.accessibilityLabel = L10n.setupAccount
            navigationItem.titleView = imageView
        }

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        if navigationController?.viewControllers.first == self {
            let dismissItem: UIBarButtonItem
            dismissItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: viewModel, action: #selector(viewModel.dismissTapped))
            dismissItem.tintColor = ThemeColor.primaryText01()
            navigationItem.rightBarButtonItem = dismissItem
        }

        if FeatureFlag.newOnboardingAccountCreation.enabled {
            let dismissItem = UIBarButtonItem(title: L10n.eoyNotNow, style: .plain, target: viewModel, action: #selector(viewModel.dismissTapped))
            dismissItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.font(with: .body, weight: .regular),
                                                NSAttributedString.Key.foregroundColor: iconTintColor], for: .normal)
            navigationItem.rightBarButtonItem = dismissItem
        }

        navigationController?.navigationBar.isHidden = false
    }
}
