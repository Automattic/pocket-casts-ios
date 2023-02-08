import Foundation
import SwiftUI

class ImportHostingController<Content>: OnboardingHostingViewController<Content> where Content: View {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel = viewModel as? ImportViewModel else { return }

        if navigationController?.viewControllers.first == self {
            let dismissItem = UIBarButtonItem(title: L10n.accessibilityDismiss, style: .plain, target: viewModel, action: #selector(viewModel.dismissTapped))
            dismissItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.font(with: .body, weight: .medium),
                                                NSAttributedString.Key.foregroundColor: iconTintColor], for: .normal)
            navigationItem.rightBarButtonItem = dismissItem
        }

        navigationController?.navigationBar.isHidden = false
    }
}
